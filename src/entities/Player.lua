-- Dependancies
local Vector = require "libs.hump.vector"
local DebugFlags = require "src.debug.DebugFlags"

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

    -- Position
    self.pos = Vector(x, y)

    self._prevPos = self.pos:clone()

    -- Sprites
    self.sprite = love.graphics.newImage("assets/graphics/sprites/player/player_32_64.png")

    self.w, self.h = TILE_SIZE, TILE_SIZE
    self.spriteW = TILE_SIZE
    self.spriteH = self.sprite:getHeight()
    self.type = "player"
    self.entityType = "player"
    self.controlsEnabled = true
    self.room = room

    -- Vie du joueur
    self.maxHp = 5
    self.hp = self.maxHp
    self.isDead = false

    -- Invincibilité courte après coup
    self.invincibleTime = 0
    self.invincibleDuration = 0.6

    -- Mouvement
    self.speed = 300
    self.angle = 0
    self.moveDir = Vector(0, 0)

    -- Vision
    self.visionRange = 420
    self.fov = math.rad(90)
    self.flashlight = Flashlight(self)
    self.circleRadius = self.flashlight:getCircle() + 10
    self.canSeeEnemy = false

    -- Arme
    self.weapon = Knife(self.world, self)

    -- Verre / bruit
    self.noiseCooldown = 0
    self.glassNoiseCooldown = 0.35
    self.glassNoiseRadius = 520

    -- 👣 Pas
    self.stepTimer = 0
    self.stepDelay = 0.32

    -- Ajout au monde
    self.world:add(self, self.pos.x, self.pos.y, self.w, self.h)
end

function Player:update(dt, cam)
    if not self.controlsEnabled then
        -- On garde l'orientation souris + logique passive
        return
    end

    local dir = self.moveDir
    dir.x, dir.y = 0, 0

    local hasInput = false

    if love.keyboard.isDown("z") or love.keyboard.isDown("up") then
        dir.y = dir.y - 1
        hasInput = true
    end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
        dir.y = dir.y + 1
        hasInput = true
    end
    if love.keyboard.isDown("q") or love.keyboard.isDown("left") then
        dir.x = dir.x - 1
        hasInput = true
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        dir.x = dir.x + 1
        hasInput = true
    end

    -- Déplacement
    local velocity = dir:trimmed(1) * self.speed * dt
    local goal = self.pos + velocity

    -- Sauvegarde ancienne position
    local oldPos = self._prevPos

    local ax, ay = self.world:move(self, goal.x, goal.y, WorldUtils.playerFilter)
    MathUtils.updateCoordinates(self, ax, ay)
    self.level.spatialHash:update(self)

    -- Déplacement réel ?
    local movedVector = self.pos - oldPos
    local moved = movedVector:len2() > 0.5

    -- 👣 Sons de pas (ICI)
    self:_handleStep(dt, hasInput and moved)

    -- Mémoriser position
    self._prevPos = Vector(self.pos.x, self.pos.y)

    -- Orientation souris
    local mx, my = love.mouse.getPosition()
    local wx, wy = cam:worldCoords(mx, my)

    local cx, cy = self:getCenter()
    local look = Vector(wx - cx, wy - cy)

    if look:len() > 0 then
        self.angle = math.atan2(look.y, look.x)
    end

    -- Bruit verre
    self:_handleGlassNoise(dt, cx, cy)

    -- Lampe
    self.flashlight:update(dt, cam)

    -- Arme
    self.weapon:update(dt)

    -- Invincibilité temporaire
    if self.invincibleTime > 0 then
        self.invincibleTime = math.max(0, self.invincibleTime - dt)
    end
end

function Player:draw()
    local drawY = self.pos.y + self.h - self.spriteH
    love.graphics.draw(self.sprite, self.pos.x, drawY)

    self.weapon:draw()

    self:debug()

    StyleUtils.resetColor()
end

---------------------
-- Vision
---------------------
function Player:canSee(entity)
    -- 1. Centres
    local px, py = self:getCenter()
    local ex, ey

    if entity.getCenter then
        ex, ey = entity:getCenter()
    else
        ex = entity.pos.x
        ey = entity.pos.y
    end

    -- 2. Vecteur joueur → entité
    local toTarget = Vector(ex - px, ey - py)
    local distance = toTarget:len()

    -- 3. Distance max
    if distance > self.visionRange then
        return false
    end

    -- 4. Cercle proche (vision périphérique)
    if distance <= self.circleRadius then
        if VisionUtils.hasLineOfSight(self.level, px, py, ex, ey, 1.0) then
            return true
        end
    end

    -- 5. Direction regard
    local forward = Vector(math.cos(self.angle), math.sin(self.angle))
    local dir = toTarget:normalized()

    -- 6. Angle
    local dot = forward.x * dir.x + forward.y * dir.y
    local maxAngle = math.cos(self.flashlight.coneAngle)

    if dot < maxAngle then
        return false
    end

    -- 7. Points de test (bounding box ou point unique)
    local points = {}

    local w = entity.w or 0
    local h = entity.h or 0

    if w > 0 and h > 0 then
        local ox = math.min(4, w * 0.25)
        local oy = math.min(4, h * 0.25)

        points = {
            { ex, ey },
            { entity.pos.x + ox,     entity.pos.y + oy },
            { entity.pos.x + w-ox,   entity.pos.y + oy },
            { entity.pos.x + ox,     entity.pos.y + h-oy },
            { entity.pos.x + w-ox,   entity.pos.y + h-oy },
        }
    else
        -- target ponctuelle (puzzle, bouton, etc)
        points = {
            { ex, ey }
        }
    end

    -- 8. LOS final
    for _, p in ipairs(points) do
        if VisionUtils.hasLineOfSight(self.level, px, py, p[1], p[2], 1.0) then
            return true
        end
    end

    return false
end

---------------------
-- Attaque
---------------------
function Player:attack()
    if self.weapon then
        self.weapon:tryAttack(self.angle or 0)
    end
end

function Player:takeDamage(amount)
    if self.invincibleTime > 0 or self.isDead then
        return
    end

    self.hp = self.hp - amount
    self.invincibleTime = self.invincibleDuration

    if self.hp <= 0 then
        self.hp = 0
        self.isDead = true
        -- plus tard : animation / game over
    end
end

---------------------
-- Sons
---------------------
function Player:_handleStep(dt, shouldStep)
    if not shouldStep then
        self.stepTimer = 0
        return
    end

    self.stepTimer = self.stepTimer - dt

    if self.stepTimer <= 0 then
        self:playFootstep()
        self.stepTimer = self.stepDelay
    end
end

function Player:playFootstep()
    local cx, cy = self:getCenter()
    local tile = self.level:getTileAtWorld(cx, cy)

    if tile == TILE_GLASS then
        SoundManager:playGlassStep(0.7)
    elseif tile == TILE_FLOOR or tile == TILE_CORRIDOR then
        SoundManager:playNormalStep()
    end
end

function Player:_handleGlassNoise(dt, cx, cy)
    self.noiseCooldown = math.max(0, self.noiseCooldown - dt)

    local tile = self.level:getTileAtWorld(cx, cy)

    if tile == 4 and self.noiseCooldown == 0 then
        self.noiseCooldown = self.glassNoiseCooldown
        self.level:emitNoise(cx, cy, self.glassNoiseRadius, 1.0)
    end
end

function Player:getCenter()
    return self.pos.x + self.w / 2, self.pos.y + self.h / 2
end

function Player:debug()
    if not DebugFlags.enabled or not DebugFlags.player.enabled then
        return
    end

    local cx, cy = self:getCenter()

    --------------------------------------------------
    -- FOV / Lampe torche
    --------------------------------------------------
    if DebugFlags.player.fov then
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
    end

    --------------------------------------------------
    -- Direction centrale
    --------------------------------------------------
    if DebugFlags.player.direction then
        love.graphics.setColor(0, 1, 0, 1)

        local dx = math.cos(self.angle) * self.visionRange
        local dy = math.sin(self.angle) * self.visionRange

        love.graphics.line(cx, cy, cx + dx, cy + dy)
    end

    --------------------------------------------------
    -- Cercle de portée
    --------------------------------------------------
    if DebugFlags.player.range then
        love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
        love.graphics.circle("line", cx, cy, self.visionRange)
    end

    --------------------------------------------------
    -- Infos texte (état)
    --------------------------------------------------
    if DebugFlags.player.state then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(
                string.format(
                        "canSee: %s",
                        tostring(self.canSeeEnemy)
                ),
                self.pos.x,
                self.pos.y - 40
        )
    end

    --------------------------------------------------
    -- Hitbox (Bump)
    --------------------------------------------------
    if DebugFlags.player.hitbox then
        StyleUtils.resetColor()
        local drawY = self.pos.y - self.spriteH + TILE_SIZE
        love.graphics.rectangle("line", self.pos.x, drawY, self.w, self.spriteH)
    end

    StyleUtils.resetColor()
end

return Player
