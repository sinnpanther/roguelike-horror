-- src/states/Play.lua

-- Requirements
local Camera = require "libs.hump.camera"
local Vector = require "libs.hump.vector"

local Play = {}
local Player = require "src.entities.Player"
local HUD = require "src.ui.HUD"
local Level = require "src.map.Level"

-- Utils
local WorldUtils = require "src.utils.world_utils"
local MathUtils = require "src.utils.math_utils"

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function getRoomCenterPixels(room)
    -- Cas "nouvelle Room" basée sur un rect en GRILLE (tiles)
    -- On suppose : room.rect = { x, y, w, h } en tiles
    -- => conversion en pixels via TILE_SIZE (ou room.ts)
    local ts = TILE_SIZE

    local cxTiles = room.rect.x + room.rect.w / 2
    local cyTiles = room.rect.y + room.rect.h / 2

    -- centre en pixels
    return cxTiles * ts, cyTiles * ts
end

local function placePlayerAtRoomCenter(player, room)
    local cx, cy = getRoomCenterPixels(room)

    -- Player() prend souvent x/y en top-left, donc on centre correctement si possible
    if player.w and player.h then
        return cx - player.w / 2, cy - player.h / 2
    end

    return cx, cy
end

----------------------------------------------------------------
-- State
----------------------------------------------------------------
function Play:enter()
    self.world = Bump.newWorld(64)
    self.screenW = love.graphics.getWidth()
    self.screenH = love.graphics.getHeight()
    self.levelIndex = 1

    -- Seed unique pour toute la run
    self.seed = MathUtils.generateBase36Seed(8)
    self.numericSeed = MathUtils.hashString(self.seed)

    DEBUG_CURRENT_SEED = self.seed
    DEBUG_CURRENT_LEVEL = self.levelIndex

    -- Génération du level
    self.level = Level(self.world, self.numericSeed, self.levelIndex)
    self.level:generate()

    -- Room principale (celle où on démarre)
    self.mainRoom = self.level.mainRoom

    -- Création du joueur puis placement au centre
    local spawnX, spawnY = placePlayerAtRoomCenter({ w = 0, h = 0 }, self.mainRoom) -- dummy pour coords
    self.player = Player(self.world, self.level, spawnX, spawnY)

    -- Re-ajustement si Player définit w/h après construction
    spawnX, spawnY = placePlayerAtRoomCenter(self.player, self.mainRoom)
    MathUtils.updateCoordinates(self.player, spawnX, spawnY)
    self.world:update(self.player, self.player.x, self.player.y)
    self.level.spatialHash:add(self.player)

    -- HUD + Cam
    self.hud = HUD(self.player)
    self.cam = Camera(self.player.x, self.player.y)
end

function Play:update(dt)
    -- Joueur
    self.player:update(dt, self.cam)

    if not FREEZE then
        self.level:update(dt, self.player)
    end

    -- Nettoyage des ennemis morts sur TOUTES les rooms du level
    for _, seg in ipairs(self.level.segments or {}) do
        for i = #seg.enemies, 1, -1 do
            local e = seg.enemies[i]
            if e.isDead then
                e:destroyEnemy(e, seg, i)
            end
        end
    end

    local px, py = self.player:getCenter()
    self.cam:lookAt(px, py)

    -- Flicker
    self.player.flashlight.flickerTime = self.player.flashlight.flickerTime + dt

    -- Transition (on abandonne les portes/sides pour l’instant)
    if self.player.hasReachedExit then
        self:nextLevel()
        self.player.hasReachedExit = false
    end
end

function Play:draw()
    love.graphics.clear(0, 0, 0)

    self.cam:attach()

    -- Draw : on dessine le Level entier (rooms + ennemis dans leurs draw)
    self.level:draw(self.player)

    local px, py = self.player:getCenter()
    local range = self.player.visionRange

    local nearbyEnemies = self.level.spatialHash:queryRect(
            px - range,
            py - range,
            range * 2,
            range * 2,
            function(e)
                return e.entityType == "enemy"
            end
    )

    for _, enemy in ipairs(nearbyEnemies) do
        if self.player:canSee(enemy) then
            enemy.isVisible = true
        else
            enemy.isVisible = false
        end
    end

    self.player:draw()

    if DEBUG_MODE then
        self:debug()
        self.level.spatialHash:drawDebug()
    end

    self.cam:detach()

    self.hud:draw(self.levelIndex, self.seed)


    if FLASHLIGHT_DISABLED then
        return
    end

    -- Lampe torche (stencil)
    love.graphics.stencil(function()
        self.cam:attach()

        local angle = self.player.angle or 0
        local flashlight = self.player.flashlight

        local n = love.math.noise(flashlight.flickerTime, 0.0)
        local radiusOffset = (n - 0.5) * 2 * flashlight.flickerAmp
        local outerRadius = flashlight.outerRadius + radiusOffset

        love.graphics.arc(
                "fill",
                px, py,
                outerRadius,
                angle - flashlight.coneAngle,
                angle + flashlight.coneAngle,
                48
        )

        love.graphics.circle("fill", px, py, flashlight.innerRadius)

        self.cam:detach()
    end, "replace", 1)

    love.graphics.setStencilTest("equal", 0)

    love.graphics.setStencilTest("less", 1)
    love.graphics.setColor(0, 0, 0.02, 0.98)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setStencilTest()
    love.graphics.setColor(1, 1, 1)
end

function Play:nextLevel()
    -- Fin de jeu
    if self.levelIndex >= 10 then
        GameState.switch(States.Victory, {
            seed = self.seed,
            levelIndex = self.levelIndex
        })
        return
    end

    -- --------------------------------------------------
    -- 1. Nettoyage COMPLET de l'ancien level
    -- --------------------------------------------------

    -- Retirer toutes les entités non-joueur de Bump
    WorldUtils.clearWorld(self.world)

    -- Vider explicitement le spatial hash de l'ancien level
    self.level.spatialHash.cells = {}

    -- --------------------------------------------------
    -- 2. Génération du nouveau level
    -- --------------------------------------------------

    self.levelIndex = self.levelIndex + 1
    DEBUG_CURRENT_LEVEL = self.levelIndex

    self.level = Level(self.world, self.numericSeed, self.levelIndex)
    self.level:generate()
    self.mainRoom = self.level.mainRoom
    self.player.level = self.level

    -- --------------------------------------------------
    -- 3. Repositionnement du joueur
    -- --------------------------------------------------

    local cx, cy = self.mainRoom:centerTile()
    local spawnX = (cx - 1) * TILE_SIZE
    local spawnY = (cy - 1) * TILE_SIZE

    MathUtils.updateCoordinates(self.player, spawnX, spawnY)
    self.world:update(self.player, self.player.x, self.player.y)

    -- IMPORTANT : ré-enregistrer le player dans le spatial hash
    self.level.spatialHash:add(self.player)

    -- --------------------------------------------------
    -- 4. Reset état transition
    -- --------------------------------------------------
    self.player.hasReachedExit = false
end


function Play:keypressed(key)
    if key == "r" then
        GameState.switch(Play)
    end

    if key == "n" then
        self:nextLevel()
    end

    if key == "tab" then
        local Menu = require "src.states.Menu"
        GameState.switch(Menu)
    end

    -- Commandes
    if key == "space" then
        self.player:attack()
    end
end

function Play:mousepressed(x, y, button)
    if button == 1 then -- clic gauche
        self.player:attack()
    end
end

function Play:debug()
    love.graphics.setColor(0, 1, 1, 0.5)

    local items, len = self.world:getItems()
    for i = 1, len do
        local x, y, w, h = self.world:getRect(items[i])
        love.graphics.rectangle("line", x, y, w, h)
        love.graphics.print(items[i].type or "unknown", x, y - 15)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("DEBUG MODE - FPS: " .. love.timer.getFPS(), 10, 10, self.screenW - 20, "right")
end

return Play
