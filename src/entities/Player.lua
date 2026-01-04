-- Dependancies
local Vector = require "libs.hump.vector"
-- Utils
local WorldUtils = require "src.utils.world_utils"
local MathUtils = require "src.utils.math_utils"
local VisionUtils = require "src.utils.vision_utils"

-- Entities
local Flashlight = require "src.entities.lighting.Flashlight"
local Knife = require "src.entities.weapons.Knife"

local Player = Class:extend()

function Player:new(world, level, x, y, room)
    self.world = world
    self.level = level
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
    self.visionRange = 420        -- portée réelle
    self.fov = math.rad(90)      -- 90° (cone)

    self.flashlight = Flashlight(self)
    self.canSeeEnemy = false

    -- Arme équipée : couteau
    self.weapon = Knife(self.world, self)

    -- L'entité s'ajoute elle-même au monde
    self.world:add(self, self.pos.x, self.pos.y, self.w, self.h)
end

function Player:update(dt, cam)
    local dir = self.moveDir
    dir.x, dir.y = 0, 0

    -- Handle keyboard inputs (WASD / ZQSD support)
    if love.keyboard.isDown("z") or love.keyboard.isDown("up") then dir.y = dir.y - 1 end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then dir.y = dir.y + 1 end
    if love.keyboard.isDown("q") or love.keyboard.isDown("left") then dir.x = dir.x - 1 end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then dir.x = dir.x + 1 end

    -- mouvement
    local velocity = dir:trimmed(1) * self.speed * dt
    local goal = self.pos + velocity

    local ax, ay = self.world:move(self, goal.x, goal.y, WorldUtils.playerFilter)
    MathUtils.updateCoordinates(self, ax, ay)
    self.level.spatialHash:update(self)

    -- === ORIENTATION SOURIS ===
    local mx, my = love.mouse.getPosition()
    local wx, wy = cam:worldCoords(mx, my)

    local cx = self.pos.x + self.w / 2
    local cy = self.pos.y + self.h / 2

    local look = Vector(wx - cx, wy - cy)

    if look:len() > 0 then
        self.angle = math.atan2(look.y, look.x)
    end

    self.flashlight:update(dt, cam)

    -- Mise à jour de l'arme
    self.weapon:update(dt)
end

function Player:draw()
    -- Draw player placeholder
    love.graphics.setColor(0.2, 0.6, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    -- Dessin de l'arme (slash, etc.)
    self.weapon:draw()

    if DEBUG_MODE then
        self:debug()
    end

    love.graphics.setColor(1, 1, 1)
end

------------
-- Vision --
------------

function Player:canSee(enemy)
    -- 1. Vecteur joueur -> ennemi
    local toEnemy = enemy.pos - self.pos
    local distance = toEnemy:len()

    -- 2. Test distance
    if distance > self.visionRange then
        return false
    end

    -- 3. Direction du regard du joueur
    local forward = Vector(math.cos(self.angle), math.sin(self.angle))

    -- 4. Normalisation
    local dir = toEnemy:normalized()

    -- 5. Produit scalaire
    local dot = forward.x * dir.x + forward.y * dir.y

    -- 6. Angle max autorisé
    local maxAngle = math.cos(self.flashlight.coneAngle)

    -- 7. Test angle
    if dot < maxAngle then
        return false
    end

    local w, h = enemy.w or 0, enemy.h or 0
    local ox = math.min(4, w * 0.25)
    local oy = math.min(4, h * 0.25)
    local px, py = self:getCenter()
    local ex, ey = enemy:getCenter()

    local points = {
        { ex, ey },
        { enemy.x + ox,     enemy.y + oy },
        { enemy.x + w-ox,   enemy.y + oy },
        { enemy.x + ox,     enemy.y + h-oy },
        { enemy.x + w-ox,   enemy.y + h-oy },
    }

    local visible = false
    for _, p in ipairs(points) do
        if VisionUtils.hasLineOfSight(self.level, px, py, p[1], p[2], 1.0) then
            visible = true
            break
        end
    end

    if not visible then
        return false
    end

    return true
end

-------------
-- Attaque --
-------------

-- Appelé par Play quand on appuie sur espace
function Player:attack()
    if self.weapon then
        self.weapon:tryAttack(self.angle or 0)
    end
end

function Player:getCenter()
    return self.x + self.w / 2, self.y + self.h / 2
end

function Player:getVCenter()
    return Vector(self.x + self.w / 2, self.y + self.h / 2)
end

function Player:debug()
    local cx, cy = self:getCenter()

    -- Lampe torche
    love.graphics.setColor(0, 0, 1, 0.10)
    love.graphics.arc(
            "fill",
            cx,
            cy,
            self.visionRange,
            self.angle - self.flashlight.coneAngle,
            self.angle + self.flashlight.coneAngle,
            32
    )
    love.graphics.setColor(0, 0, 1)

     -- Infos
    love.graphics.print(
            string.format(
                    "canSee: %s",
                    tostring(self.canSeeEnemy)
            ),
            self.x,
            self.y - 40
    )

    -- Direction centrale (ligne)
    love.graphics.setColor(0, 1, 0, 1)
    local dx = math.cos(self.angle) * self.visionRange
    local dy = math.sin(self.angle) * self.visionRange
    love.graphics.line(cx, cy, cx + dx, cy + dy)

    -- Point central
    love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
    love.graphics.circle("line", cx, cy, self.visionRange)

    love.graphics.setColor(1, 1, 1)
end

return Player