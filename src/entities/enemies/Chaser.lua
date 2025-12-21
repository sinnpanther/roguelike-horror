-- Dependancies
local Enemy = require "src.entities.enemies.Enemy"
-- Utils
local WorldUtils = require "src.utils.world_utils"

local Chaser = Enemy:extend()

function Chaser:new(world, x, y)
    -- HP: 3, Speed: 80
    Chaser.super.new(self, world, x, y, 3, 80)
end

function Chaser:update(dt, player)
    -- 1. Calculer la direction vers le joueur
    local dx = player.x - self.x
    local dy = player.y - self.y
    local distance = math.sqrt(dx*dx + dy*dy)

    -- 2. Normaliser le mouvement (pour ne pas aller plus vite en diagonale)
    if distance > 0 then
        self.vx = (dx / distance) * self.speed
        self.vy = (dy / distance) * self.speed
    end

    -- 3. Appliquer le mouvement avec Bump
    local goalX = self.x + self.vx * dt
    local goalY = self.y + self.vy * dt

    local actualX, actualY, cols, len = self.world:move(self, goalX, goalY, WorldUtils.enemyFilter)

    self.x, self.y = actualX, actualY
end

return Chaser