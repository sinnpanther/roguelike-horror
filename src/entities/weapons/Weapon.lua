local Vector = require "libs.hump.vector"

local Weapon = Class:extend()

function Weapon:new(world, player)
    self.world = world
    self.player = player
    self.type = "weapon"
    self.entityType = "weapon"

    -- Hitbox logique (PAS un item Bump)
    self.pos = player.pos
    self.w, self.h = 16, 16

    -- Etat d'activation (coup en cours)
    self.active   = false
    self.duration = 0.10        -- durée d'un coup
    self.timer    = 0

    -- Gestion du rythme d'attaque (cooldown entre 2 coups)
    self.cooldown      = 0.40   -- temps mini entre 2 attaques
    self.cooldownTimer = 0

    self.damage  = 1
    self.angle   = 0
end

-- Demande d'attaque (ne part que si cooldown OK)
function Weapon:tryAttack(angle)
    if self.cooldownTimer > 0 then
        return
    end

    self.cooldownTimer = self.cooldown
    self:activate(angle)
end

-- Active l'arme (un "coup")
function Weapon:activate(angle)
    if self.active then
        return
    end

    self.active = true
    self.timer  = self.duration
    self.angle  = angle or 0

    self:updatePosition()
    self:applyDamage()
end

function Weapon:update(dt)
    -- Cooldown global
    if self.cooldownTimer > 0 then
        self.cooldownTimer = math.max(0, self.cooldownTimer - dt)
    end

    -- Si le coup n'est pas actif, rien d'autre à faire
    if not self.active then
        return
    end

    -- Durée de vie du coup
    self.timer = self.timer - dt
    self:updatePosition()
    self:applyDamage()

    if self.timer <= 0 then
        self.active = false
    end
end

-- Méthode à surcharger par les armes concrètes
function Weapon:updatePosition()
    -- Par défaut : attaché au centre du player
    local px, py = self.player:getCenter()
    self.pos.x = px - self.w / 2
    self.pos.y = py - self.h / 2
end

function Weapon:applyDamage()
    error("add applyDamage()")
end

function Weapon:draw()
    error("add draw()")
end

return Weapon
