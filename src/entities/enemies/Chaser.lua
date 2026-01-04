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

return Chaser