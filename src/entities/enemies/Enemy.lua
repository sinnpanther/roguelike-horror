local Vector = require "libs.hump.vector"

local Enemy = Class:extend()

function Enemy:new(world, x, y, hp, speed)
    self.world = world
    self.x, self.y = x, y
    self.pos = Vector(x, y)
    self.w = 32
    self.h = 32
    self.hp = hp or 3
    self.speed = speed or 100
    self.type = "enemy" -- Important pour WorldUtils.clearWorld !

    self.vx = 0
    self.vy = 0

    -- Ajout au monde physique
    self.world:add(self, self.x, self.y, self.w, self.h)
end

-- Méthode à redéfinir par les enfants (l'IA)
function Enemy:update(dt, player)
    error("La méthode update doit être implémentée par le type d'ennemi")
end

function Enemy:draw()
    -- Debug visuel : un rectangle rouge par défaut
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    love.graphics.setColor(1, 1, 1)
end

return Enemy