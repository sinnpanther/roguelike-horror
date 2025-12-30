-- Dependancies
local Enemy = require "src.entities.enemies.Enemy"
local Vector = require "libs.hump.vector"
-- Utils
local WorldUtils = require "src.utils.world_utils"
local MathUtils = require "src.utils.math_utils"

local Watcher = Enemy:extend()

function Watcher:new(world, x, y)
    Watcher.super.new(self, world, x, y)

    self.pos = Vector(x, y)
    self.hp = 3
    self.maxHp = self.hp
    self.speed = 40
    self.type = "watcher"
    self.color = {
        red = 0,
        green = 1,
        blue = 0,
        alpha = 1
    }
end

function Watcher:update(dt, player)
    local seen = self:isEnemyVisible(player)
    local px, py = player:getCenter()
    local ex, ey = self:getCenter()

    if seen then
        -- figé
        self.vx, self.vy = 0, 0
        return
    end

    -- déplacement vers le joueur
    local dir = Vector(
            px - ex,
            py - ey
    ):normalized()

    local goalX = self.x + dir.x * self.speed * dt
    local goalY = self.y + dir.y * self.speed * dt

    local ax, ay, cols, len = self.world:move(self, goalX, goalY, WorldUtils.enemyFilter)

    -- 4. Mise à jour des coordonnées
    MathUtils.updateCoordinates(self, ax, ay)
end

return Watcher
