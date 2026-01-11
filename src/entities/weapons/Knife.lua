local Vector = require "libs.hump.vector"

local Weapon = require "src.entities.weapons.Weapon"

local Knife = Weapon:extend()

function Knife:new(world, player)
    Knife.super.new(self, world, player)

    self.w        = 34      -- longueur de la hitbox
    self.h        = 12      -- épaisseur
    self.damage   = 1
    self.duration = 0.12    -- temps pendant lequel le coup est "actif"
    self.cooldown = 0.40    -- délai avant de pouvoir réattaquer

    -- Distance depuis le centre du joueur
    self.offset = player.w * 0.5 + self.w * 0.35

    -- Set des ennemis déjà touchés pendant CE coup
    self.alreadyHit = {}
end

function Knife:activate(angle)
    -- On vide le set des ennemis touchés pour ce nouveau coup
    self.alreadyHit = {}
    Knife.super.activate(self, angle)
end

-- Positionne le couteau devant le joueur (logique seulement)
function Knife:updatePosition()
    local player = self.player
    local px, py = player:getCenter()
    local dx = math.cos(self.angle)
    local dy = math.sin(self.angle)

    local cx = px + dx * self.offset
    local cy = py + dy * self.offset

    self.pos = Vector(cx - self.w / 2, cy - self.h / 2)
end

function Knife:applyDamage()
    if not self.active then
        return
    end

    local function filter(item)
        return item.entityType == "enemy"
    end

    local items, len = self.world:queryRect(self.pos.x, self.pos.y, self.w, self.h, filter)
    if len == 0 then
        return
    end

    for i = 1, len do
        local enemy = items[i]

        -- Ne pas retaper le même ennemi pendant le même coup
        if not enemy.isDead and not self.alreadyHit[enemy] then
            self.alreadyHit[enemy] = true

            -- APPEL CENTRAL
            enemy:onHit(self.damage, self.angle)
        end
    end
end

function Knife:draw()
    if not self.active then
        return
    end

    -- Visuel du slash : petit arc devant le joueur
    local px, py = self.player:getCenter()
    local r = self.offset + self.w * 0.5

    StyleUtils.resetColor()
    love.graphics.arc(
        "line",
        px, py,
        r,
        self.angle - math.rad(25),
        self.angle + math.rad(25)
    )
end

function Knife:slash(angle)
    self:tryAttack(angle)
end

return Knife
