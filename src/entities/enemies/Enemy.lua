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

    -- Valeur de debug
    if DEBUG_MODE then
        local pos = {x=0, y=0}
        self.debug_hitL, self.debug_rayL, self.debug_hitR, self.debug_rayR = pos, pos, pos, pos
    end

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

    if DEBUG_MODE then
        self:debug()
    end

    love.graphics.setColor(1, 1, 1)
end

-- AFFICHAGE DEBUG
function Enemy:debug()
    -- Position centrale pour le départ des rayons
    local cx, cy = self.x + self.w/2, self.y + self.h/2

    -- Rayon Gauche
    if self.debug_hitL then love.graphics.setColor(1, 0, 0) else love.graphics.setColor(0, 1, 0) end
    if self.debug_rayL then love.graphics.line(cx, cy, self.debug_rayL.x, self.debug_rayL.y) end

    -- Rayon Droit
    if self.debug_hitR then love.graphics.setColor(1, 0, 0) else love.graphics.setColor(0, 1, 0) end
    if self.debug_rayR then love.graphics.line(cx, cy, self.debug_rayR.x, self.debug_rayR.y) end

    -- Hitbox Bump (en blanc)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
end

return Enemy