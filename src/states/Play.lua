-- Requirements
local Camera = require "libs.hump.camera"

local Play = {}
local Player = require "src.entities.Player"
local HUD = require "src.ui.HUD"
--local Item = require "src.entities.items.Item"
local Room = require "src.entities.Room"

-- Utils
local WorldUtils = require "src.utils.world_utils"
local MathUtils = require "src.utils.math_utils"

function Play:enter()
    self.world = Bump.newWorld(64)
    self.level = 1

    -- On génère la seed une seule fois
    self.seed = MathUtils.generateBase36Seed(8)
    self.numericSeed = MathUtils.hashString(self.seed)

    DEBUG_CURRENT_SEED = self.seed
    DEBUG_CURRENT_LEVEL = self.level

    -- On crée la première salle
    self.room = Room(self.world, self.numericSeed, self.level)

    -- On place le joueur au milieu de cette salle
    self.player = Player(self.room.x + self.room.width/2, self.room.y + self.room.height/2)
    self.world:add(self.player, self.player.x, self.player.y, self.player.w, self.player.h)

    -- HUD
    self.hud = HUD(self.player)

    self.cam = Camera(self.player.x, self.player.y)
end

function Play:update(dt)
    -- Update player logic (movement + collisions)
    self.player:update(dt, self.world)

    -- Smoothly follow the player with the camera
    -- The third argument (0.1) adds a bit of "lag" for a smoother feel
    local targetX = self.player.x + self.player.w / 2
    local targetY = self.player.y + self.player.h / 2
    self.cam:lookAt(targetX, targetY)
end

function Play:draw()
    -- 1. Tout ce qui est DANS le monde (Camera)
    self.cam:attach()

    self.room:draw()
    self.player:draw()

    self.cam:detach()

    -- Le HUD affiche les infos du niveau actuel
    self.hud:draw(self.level, self.seed)
end

function Play:nextLevel()
    -- 1. On nettoie l'ancien monde
    WorldUtils.clearWorld(self.world, self.room.walls)

    -- 2. On augmente le niveau et on crée la nouvelle salle
    self.level = self.level + 1
    self.room = Room(self.world, self.numericSeed, self.level)

    -- 3. On replace le joueur (au centre de la nouvelle salle)
    self.player.x = self.room.x + self.room.width/2
    self.player.y = self.room.y + self.room.height/2
    self.world:update(self.player, self.player.x, self.player.y)
end

function Play:keypressed(key)
    -- 1. Check if the pressed key is 'r'
    if key == "r" then
        -- 2. Tell GameState to switch to 'Play' again
        -- This will call Play:enter() and reset everything
        GameState.switch(Play)
    end

    -- 2. Next level
    if key == "n" then
        self:nextLevel()
    end

    -- 3. Return to menu if Escape is pressed
    if key == "tab" then
        local Menu = require "src.states.Menu"
        GameState.switch(Menu)
    end
end

return Play