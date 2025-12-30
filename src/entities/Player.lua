-- Dependancies
local Vector = require "libs.hump.vector"
-- Utils
local WorldUtils = require "src.utils.world_utils"
local MathUtils = require "src.utils.math_utils"
-- Entities
local Knife = require "src.entities.weapons.Knife"

local Player = Class:extend()

function Player:new(world, x, y, room)
    self.world = world
    -- Initial position and dimensions
    self.x, self.y = x, y
    self.pos = Vector(x, y)
    self.w, self.h = 32, 32 -- Rectangle size for collision
    self.type = "player"
    self.entityType = "player"
    self.room = room

    -- Movement settings
    self.speed = 300
    self.angle = 0 -- Direction de la lampe / de l'arme
    self.moveDir = Vector(0, 0)

    self.flashlight = {
        coneAngle = 0.45,
        innerRadius = 40,
        outerRadius = 300,
        flickerAmp = 5,
        flickerTime = 0
    }

    -- Horror mechanics
    self.fear = 0
    self.fearGain = 5

    -- Arme équipée : couteau
    self.weapon = Knife(self.world, self)

    -- L'entité s'ajoute elle-même au monde
    self.world:add(self, self.pos.x, self.pos.y, self.w, self.h)
end

function Player:update(dt)
    local dir = self.moveDir
    dir.x, dir.y = 0, 0

    -- Handle keyboard inputs (WASD / ZQSD support)
    if love.keyboard.isDown("z") or love.keyboard.isDown("up") then dir.y = dir.y - 1 end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then dir.y = dir.y + 1 end
    if love.keyboard.isDown("q") or love.keyboard.isDown("left") then dir.x = dir.x - 1 end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then dir.x = dir.x + 1 end

    -- Mise à jour de l'angle seulement si on bouge
    if dir:len() > 0 then
        self.angle = math.atan2(dir.y, dir.x)
    end

    -- 2. Déplacement
    local velocity = dir:trimmed(1) * self.speed * dt
    local goal = self.pos + velocity

    local ax, ay, cols, len = self.world:move(self, goal.x, goal.y, WorldUtils.playerFilter)
    MathUtils.updateCoordinates(self, ax, ay)

    for i=1, len do
        local col = cols[i]
        if col.other.onInteract then
            col.other:onInteract(self)
        end
    end

    -- Mise à jour de l'arme
    self.weapon:update(dt)
end

function Player:draw()
    -- Draw player placeholder
    love.graphics.setColor(0.2, 0.6, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    -- Dessin de l'arme (slash, etc.)
    self.weapon:draw()

    love.graphics.setColor(1, 1, 1)
end

-- Appelé par Play quand on appuie sur espace
function Player:attack()
    if self.weapon and self.weapon.slash then
        self.weapon:slash(self.angle or 0)
    end
end

function Player:getCenter()
    return self.x + self.w / 2, self.y + self.h / 2
end

return Player