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
-- State
----------------------------------------------------------------
function Play:enter()
    self.world = Bump.newWorld(64)
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

    local spawnX, spawnY = self.mainRoom:getRandomSpawn()
    self.player = Player(self.world, self.level, spawnX, spawnY)

    -- si w/h sont définis après
    spawnX, spawnY = self.mainRoom:getRandomSpawn(self.player)
    MathUtils.updateCoordinates(self.player, spawnX, spawnY)
    self.world:update(self.player, self.player.x, self.player.y)
    self.level.spatialHash:add(self.player)

    -- HUD + Cam
    self.hud = HUD(self.player)
    self.cam = Camera(self.player.x, self.player.y)
    self.cam:zoomTo(1.2)
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
        if self.player:canSee(enemy, dt) then
            enemy.isVisible = true
            self.player.canSeeEnemy = true
        else
            enemy.isVisible = false
            self.player.canSeeEnemy = false
        end
    end

    self.cam:lookAt(px, py)

    -- Flicker
    --self.player.flashlight.flickerTime = self.player.flashlight.flickerTime + dt

    -- Transition (on abandonne les portes/sides pour l’instant)
    if self.player.hasReachedExit then
        self:nextLevel()
        self.player.hasReachedExit = false
    end
end

local function attachCamSnapped(self)
    -- On snap la position camera à l'entier pour éviter les seams MSAA
    local cx, cy = self.cam:position()
    self._camSavedX, self._camSavedY = cx, cy
    self.cam:lookAt(math.floor(cx + 0.5), math.floor(cy + 0.5))
    self.cam:attach()
end

local function detachCamSnapped(self)
    self.cam:detach()
    -- On restaure la position "réelle" (pour ne pas impacter update / logique)
    if self._camSavedX then
        self.cam:lookAt(self._camSavedX, self._camSavedY)
        self._camSavedX, self._camSavedY = nil, nil
    end
end

function Play:draw()
    love.graphics.setCanvas( {POST_CANVAS, stencil = true })
    love.graphics.clear()

    --------------------------------------------------
    -- 1. DESSIN NORMAL DU MONDE (CAM SNAP)
    --------------------------------------------------
    attachCamSnapped(self)
    self.level:draw(self.player)
    self.player:draw()

    if DEBUG_MODE then
        self:debug()
        self.level.spatialHash:drawDebug()
    end
    detachCamSnapped(self)

    if FLASHLIGHT_DISABLED then
        love.graphics.setCanvas()

        -- Dessin direct (sans post-process)
        love.graphics.draw(POST_CANVAS, 0, 0)

        self.hud:draw(self.levelIndex, self.seed)

        return
    end

    --------------------------------------------------
    -- 2. PÉNOMBRE GLOBALE
    --------------------------------------------------
    love.graphics.setColor(0, 0, 0, 0.88)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1)

    --------------------------------------------------
    -- 2 bis. ANNULER LA PÉNOMBRE SUR LES MURS
    -- (on redessine les murs au-dessus du voile noir)
    --------------------------------------------------
    --attachCamSnapped(self)
    --self.level:drawWallsOnly()
    --detachCamSnapped(self)

    --------------------------------------------------
    -- 3. STENCIL : LAMPE TORCHE (CAM SNAP)
    --------------------------------------------------
    love.graphics.stencil(function()
        attachCamSnapped(self)

        -- cône : raycast sur murs
        self.player.flashlight:drawIrregularCone(self.level)

        -- cercle central (lissé)
        local fx, fy = self.player.flashlight:getPosition()
        local circle = self.player.flashlight:getCircle()
        love.graphics.circle("fill", fx + 0.5, fy + 0.5, circle, 64)

        self.cam:detach()
    end, "replace", 1)

    --------------------------------------------------
    -- 4. RETIRER LA PÉNOMBRE DANS LE STENCIL (CAM SNAP)
    --------------------------------------------------
    love.graphics.setStencilTest("equal", 1)

    attachCamSnapped(self)
    self.level:draw(self.player)
    self.player:draw()
    detachCamSnapped(self)

    love.graphics.setStencilTest()

    love.graphics.setCanvas()

    --------------------------------------------------
    -- 6. POST-PROCESS : VHS
    --------------------------------------------------
    VHS_SHADER:send("time", love.timer.getTime())
    VHS_SHADER:send("intensity", 0.4)

    love.graphics.setShader(VHS_SHADER)
    love.graphics.draw(POST_CANVAS, 0, 0)
    love.graphics.setShader()
    --------------------------------------------------
    -- 5. HUD
    --------------------------------------------------
    self.hud:draw(self.levelIndex, self.seed)
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

    local spawnX, spawnY = self.mainRoom:getRandomSpawn(self.player)
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
end

return Play
