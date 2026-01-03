-- Dependancies
local Enemy = require "src.entities.enemies.Enemy"
local Vector = require "libs.hump.vector"
-- Utils
local WorldUtils = require "src.utils.world_utils"
local MathUtils = require "src.utils.math_utils"

local Chaser = Enemy:extend()

function Chaser:new(world, level, x, y)
    -- HP: 3, Speed: 80
    Chaser.super.new(self, world, level, x, y)
    self.hp = 3
    self.maxHp = self.hp
    self.speed = 80
    self.type = "chaser"
    self.color = {
        red = 1,
        green = 0,
        blue = 0,
        alpha = 1
    }
end

function Enemy:chaseBehavior(dt, player)
    local dir = (player.pos - self.pos):normalized()
    self.angle = math.atan2(dir.y, dir.x)

    local velocity = dir * self.speed * dt
    local goal = self.pos + velocity

    local ax, ay = self.world:move(self, goal.x, goal.y, WorldUtils.enemyFilter)
    MathUtils.updateCoordinates(self, ax, ay)
    self.level.spatialHash:update(self)
end

return Chaser