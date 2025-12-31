-- Dependancies
local Enemy = require "src.entities.enemies.Enemy"
local Vector = require "libs.hump.vector"
-- Utils
local WorldUtils = require "src.utils.world_utils"
local MathUtils = require "src.utils.math_utils"

local Watcher = Enemy:extend()

function Watcher:new(world, level, x, y)
    Watcher.super.new(self, world, level, x, y)

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
    self.state = 'default'

    if self:isInPlayerRange(player) then
        self.state = "chase"
    end

    if player:canSee(self) then
        self.state = "frozen"
    end

    if self.state == "chase" then
        -- Position de l'ennemi
        local ePos = self.pos
        -- Position du joueur
        local targetPos = player.pos
        local dir = (targetPos - ePos):normalized()

        local goalX = self.x + dir.x * self.speed * dt
        local goalY = self.y + dir.y * self.speed * dt

        local ax, ay, cols, len = self.world:move(self, goalX, goalY, WorldUtils.enemyFilter)

        -- 4. Mise à jour des coordonnées
        MathUtils.updateCoordinates(self, ax, ay)
        self.level.spatialHash:update(self)
    end
end

return Watcher
