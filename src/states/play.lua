local Play = {}
local Player = require "src.entities.Player"

-- Requirements
local Camera = require "src.libs.hump.camera"

function Play:enter()
    -- Initialize collision world (cell size 64)
    self.world = Bump.newWorld(64)

    -- Create the camera instance
    self.cam = Camera(love.graphics.getWidth()/2, love.graphics.getHeight()/2)

    -- Instantiate the player
    self.player = Player(400, 300)

    -- Add player to the bump world
    self.world:add(self.player, self.player.x, self.player.y, self.player.w, self.player.h)

    -- Add some placeholder walls to test collisions
    self.walls = {
        {x = 100, y = 100, w = 50, h = 400},
        {x = 600, y = 200, w = 200, h = 50}
    }

    for _, wall in ipairs(self.walls) do
        self.world:add(wall, wall.x, wall.y, wall.w, wall.h)
    end
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
    -- 1. Draw everything affected by the Camera (The Game World)
    self.cam:attach()

    -- Draw walls
    love.graphics.setColor(0.5, 0.5, 0.5)
    for _, wall in ipairs(self.walls) do
        love.graphics.rectangle("line", wall.x, wall.y, wall.w, wall.h)
    end

    -- Draw player
    self.player:draw()

    self.cam:detach()

    -- 2. Draw UI (Not affected by the camera)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Fear Level: " .. math.floor(self.player.fear), 20, 20)
    love.graphics.print("Sanity: " .. math.floor(self.player.sanity) .. "%", 20, 40)
    love.graphics.print("Use WASD to move", 20, love.graphics.getHeight() - 30)
end

return Play