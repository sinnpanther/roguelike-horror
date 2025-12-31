local Vector = require "libs.hump.vector"
local MathUtils = require "src.utils.math_utils"

local Enemy = Class:extend()

function Enemy:new(world, level, x, y)
    self.world = world
    self.level = level
    self.x, self.y = x, y
    self.pos = Vector(x, y)
    self.w = 32
    self.h = 32
    self.hp = 3
    self.maxHp = self.hp
    self.speed = 100
    self.type = "enemy"
    self.entityType = "enemy"
    self.state = 'default'
    self.color = {
        red = 1,
        green = 1,
        blue = 1,
        alpha = 1
    }

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
    if not self.isVisible and not DEBUG_MODE then
        return
    end

    -- Corps de l'ennemi
    love.graphics.setColor(self.color.red, self.color.green, self.color.blue, self.color.alpha)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    -- --- BARRE DE VIE AU-DESSUS ---
    if self.maxHp and self.maxHp > 0 then
        local barWidth  = self.w
        local barHeight = 4
        local margin    = 3  -- espace entre le haut du sprite et la barre

        local x = self.x
        local y = self.y - barHeight - margin

        -- Fond sombre
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", x, y, barWidth, barHeight)

        -- Pourcentage de vie
        local ratio = math.max(0, math.min(1, self.hp / self.maxHp))

        -- Barre de vie (vert)
        love.graphics.setColor(0.1, 0.8, 0.1, 1)
        love.graphics.rectangle("fill", x, y, barWidth * ratio, barHeight)
    end

    if DEBUG_MODE then
        self:debug()
    end

    love.graphics.setColor(1, 1, 1)
end

function Enemy:isInPlayerRange(player)
    -- 1. Vecteur joueur -> ennemi
    local toPlayer = self.pos - player.pos
    local distance = toPlayer:len()

    -- 2. Test distance
    if distance > player.visionRange then
        return false
    end

    return true
end

function Enemy:getCenter()
    return self.x + self.w / 2, self.y + self.h / 2
end

function Enemy:getVCenter()
    return Vector(self.x + self.w / 2, self.y + self.h / 2)
end

function Enemy:destroyEnemy(enemy, room, index)
    self.world:remove(enemy)
    self.level.spatialHash:remove(enemy)
    table.remove(room.enemies, index)
end

-- AFFICHAGE DEBUG
function Enemy:debug()
    -- Position centrale pour le départ des rayons
    local cx, cy = self.x + self.w/2, self.y + self.h/2

    love.graphics.setColor(1, 0, 0)
    -- Rayon Gauche
    if self.debug_rayL then love.graphics.line(cx, cy, self.debug_rayL.x, self.debug_rayL.y) end
    -- Rayon Droit
    if self.debug_rayR then love.graphics.line(cx, cy, self.debug_rayR.x, self.debug_rayR.y) end

    -- Hitbox Bump (en blanc)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
end

return Enemy