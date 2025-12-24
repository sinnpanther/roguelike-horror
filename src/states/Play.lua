-- Requirements
local Camera = require "libs.hump.camera"
local Vector = require "libs.hump.vector"

local Play = {}
local Player = require "src.entities.Player"
local HUD = require "src.ui.HUD"
local Room = require "src.entities.rooms.Room"

-- Utils
local WorldUtils = require "src.utils.world_utils"
local MathUtils = require "src.utils.math_utils"

function Play:enter()
    self.world = Bump.newWorld(64)
    self.screenW = love.graphics.getWidth()
    self.screenH = love.graphics.getHeight()
    self.level = 1

    -- On génère la seed une seule fois
    self.seed = MathUtils.generateBase36Seed(8)
    self.numericSeed = MathUtils.hashString(self.seed)

    DEBUG_CURRENT_SEED = self.seed
    DEBUG_CURRENT_LEVEL = self.level

    -- On crée la première salle
    self.room = Room(self.world, self.numericSeed, self.level)
    self.room:generate()

    -- On place le joueur au milieu de cette salle
    self.player = Player(self.world, self.room.x + self.room.width/2, self.room.y + self.room.height/2)

    -- HUD
    self.hud = HUD(self.player)

    self.cam = Camera(self.player.x, self.player.y)

    self.flashlight = {
        coneAngle = 0.45,  -- demi-angle du cône (en radians)
        innerRadius = 30,  -- petit halo autour du joueur
        outerRadius = 300, -- portée principale
        flickerAmp = 5     -- amplitude max du flicker sur le rayon
    }
    self.flickerTime = 0  -- temps pour le bruit de Perlin
end

function Play:update(dt)
    -- Update player logic (movement + collisions + weapon)
    self.player:update(dt)

    -- Update des ennemis (seulement si l'IA n'est pas figée)
    if not FREEZE then
        for _, enemy in ipairs(self.room.enemies) do
            enemy:update(dt, self.player)
        end
    end

    -- Nettoyage des ennemis morts
    for i = #self.room.enemies, 1, -1 do
        local e = self.room.enemies[i]
        if e.isDead then
            self.world:remove(e)
            table.remove(self.room.enemies, i)
        end
    end

    local pCenter = self.player:getCenter()
    self.cam:lookAt(pCenter.x, pCenter.y)

    -- Flicker
    self.flickerTime = self.flickerTime + dt

    if self.player.hasReachedExit then
        self:nextLevel()
        self.player.hasReachedExit = false
    end
end

function Play:draw()
    -- 1. On dessine d'abord le fond noir
    love.graphics.clear(0, 0, 0)

    -- Regard à travers la caméra
    self.cam:attach()

    -- Dessine la pièce + ennemis + joueur (arme incluse dans Player:draw)
    self.room:draw()
    self.player:draw()

    self.cam:detach()

    -- Si la lampe est désactivée : HUD + debug seulement
    if not FLASHLIGHT_ENABLED then
        self.hud:draw(self.level, self.seed)
        if DEBUG_MODE then
            self:debug()
        end
        return
    end

    -- 2. Active la lampe torche (stencil)
    love.graphics.stencil(function()
        self.cam:attach()

        local pCenter = self.player:getCenter()
        local angle = self.player.angle or 0

        local n = love.math.noise(self.flickerTime, 0.0)
        local radiusOffset = (n - 0.5) * 2 * self.flashlight.flickerAmp
        local outerRadius = self.flashlight.outerRadius + radiusOffset

        love.graphics.arc(
            "fill",
            pCenter.x, pCenter.y,
            outerRadius,
            angle - self.flashlight.coneAngle,
            angle + self.flashlight.coneAngle,
            48
        )

        love.graphics.circle("fill", pCenter.x, pCenter.y, self.flashlight.innerRadius)

        self.cam:detach()
    end, "replace", 1)

    love.graphics.setStencilTest("equal", 0)

    -- 3. Voile sombre bleu sur tout l'écran, sauf dans le stencil
    love.graphics.setStencilTest("less", 1)
    love.graphics.setColor(0, 0, 0.02, 0.98)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setStencilTest()
    love.graphics.setColor(1, 1, 1)

    -- HUD
    self.hud:draw(self.level, self.seed)

    if DEBUG_MODE then
        self:debug()
    end
end

function Play:nextLevel()
    if self.level >= 10 then
        local stats = {
            seed  = self.seed,
            level = self.level
        }
        GameState.switch(States.Victory, stats)
        return
    end

    local exitSide = self.player.lastExitSide
    local opposite = { north = "south", south = "north", east = "west", west = "east" }
    local entrySide = opposite[exitSide]

    -- 1. Nettoyage complet de l'ancien monde
    WorldUtils.clearWorld(self.world)

    -- 2. Nouvelle salle
    self.level = self.level + 1
    self.room = Room(self.world, self.numericSeed, self.level)
    self.room:generate(entrySide)

    -- 3. Repositionnement du joueur
    local spawnX
    local spawnY

    local entryDoor = self.room.entryDoor

    if entryDoor then
        -- Cas normal : on a une porte d'entrée, on spawn juste dedans
        spawnX = entryDoor.x
        spawnY = entryDoor.y

        if entrySide == "north" then
            spawnX = entryDoor.x + entryDoor.w / 2 - self.player.w / 2
            spawnY = entryDoor.y + entryDoor.h + 2
        elseif entrySide == "south" then
            spawnX = entryDoor.x + entryDoor.w / 2 - self.player.w / 2
            spawnY = entryDoor.y - self.player.h - 2
        elseif entrySide == "west" then
            spawnX = entryDoor.x + entryDoor.w + 2
            spawnY = entryDoor.y + entryDoor.h / 2 - self.player.h / 2
        elseif entrySide == "east" then
            spawnX = entryDoor.x - self.player.w - 2
            spawnY = entryDoor.y + entryDoor.h / 2 - self.player.h / 2
        end
    else
        -- Cas spécial : pas d'entrée (ex: première salle ou debug avec 'n')
        -- -> on spawn au centre de la room
        spawnX = self.room.x + self.room.width / 2  - self.player.w / 2
        spawnY = self.room.y + self.room.height / 2 - self.player.h / 2
    end

    MathUtils.updateCoordinates(self.player, spawnX, spawnY)
    self.world:update(self.player, self.player.x, self.player.y)

    -- 4. Reset des états liés à la transition
    self.player.hasReachedExit = false
end

function Play:keypressed(key)
    -- Reload
    if key == "r" then
        GameState.switch(Play)
    end

    -- Next level
    if key == "n" then
        self:nextLevel()
    end

    -- Attaque au couteau (arme actuelle)
    if key == "space" then
        self.player:attack()
    end

    -- Return to menu
    if key == "tab" then
        local Menu = require "src.states.Menu"
        GameState.switch(Menu)
    end
end

-- --- SECTION DEBUG GLOBALE ---
function Play:debug()
    love.graphics.setColor(0, 1, 1, 0.5)

    local items, len = self.world:getItems()
    for i = 1, len do
        local x, y, w, h = self.world:getRect(items[i])
        love.graphics.rectangle("line", x, y, w, h)
        love.graphics.print(items[i].type or "unknown", x, y - 15)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("DEBUG MODE - FPS: "..love.timer.getFPS(), 10, 10, self.screenW - 20, "right")
end

return Play