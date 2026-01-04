-- Dependancies
local Vector = require "libs.hump.vector"
-- Utils
local MathUtils = require "src.utils.math_utils"
local WorldUtils = require "src.utils.world_utils"
local VisionUtils = require "src.utils.vision_utils"

local Enemy = Class:extend()

function Enemy:new(world, level, x, y)
    Enemy._nextId = (Enemy._nextId or 0) + 1
    self.id = Enemy._nextId

    self.world = world
    self.level = level
    self.x, self.y = x, y
    self.pos = Vector(x, y)
    self.w, self.h = 32, 32
    self.hp = 3
    self.maxHp = self.hp
    self.speed = 100
    self.type = "enemy"
    self.entityType = "enemy"
    self.color = {
        red = 1,
        green = 1,
        blue = 1,
        alpha = 1
    }

    -- Attaque
    self.attackRange = 42
    self.attackAngle = math.rad(60)
    self.attackCooldown = 1.2
    self.attackTimer = 0
    self.attackDamage = 1

    -- Hit stun (quand l’ennemi est touché)
    self.hitStunTimer = 0
    self.hitStunDuration = 0.25 -- durée du cut d’élan

    -- Feedback visuel
    self.attackFlashTime = 0

    self.vx = 0
    self.vy = 0

    -- State machine
    self.state = "idle"
    self.canSeePlayer = nil
    self.stopDistance = 42

    self.visionRange = 300
    self.fov = math.rad(80)
    self.angle = 0

    self.lastSeenPlayerPos = nil
    self.timeSinceLastSeen = math.huge

    self.lastHeardNoisePos = nil
    self.timeSinceHeard = math.huge
    self.noiseMemory = 2.5

    -- Ajout au monde physique
    self.world:add(self, self.x, self.y, self.w, self.h)
end

-- Méthode à redéfinir par les enfants (l'IA)
function Enemy:update(dt, player)
    if self.attackTimer > 0 then
        self.attackTimer = self.attackTimer - dt
    end

    if self.attackFlashTime > 0 then
        self.attackFlashTime = self.attackFlashTime - dt
    end

    if self.hitStunTimer > 0 then
        self.hitStunTimer = self.hitStunTimer - dt
        return -- STOP TOTAL
    end

    self:perceive(dt, player)
    self:updateState(dt, player)
    self:act(dt, player)
end

function Enemy:perceive(dt, player)
    if self:canSee(player) then
        self.lastSeenPlayerPos = player.pos:clone()
        self.timeSinceLastSeen = 0
        self.canSeePlayer = true
    else
        self.canSeePlayer = false
        self.timeSinceLastSeen = self.timeSinceLastSeen + dt
    end
end

function Enemy:updateState(dt, player)
    if self.state == "dead" then
        return
    end

    -- 1) Priorité : si je vois le joueur récemment
    if self.lastSeenPlayerPos then
        if self.timeSinceLastSeen < 0.5 then
            self.state = "chase"
            return
        elseif self.timeSinceLastSeen < 3 then
            self.state = "search"
            return
        else
            self.lastSeenPlayerPos = nil
            -- ne return pas: on peut fallback sur le bruit
        end
    end

    -- 2) Sinon : bruit (verre)
    if self.lastHeardNoisePos then
        self.timeSinceHeard = self.timeSinceHeard + dt

        if self.timeSinceHeard <= self.noiseMemory then
            self.state = "search"
            return
        else
            self.lastHeardNoisePos = nil
        end
    end

    -- 3) Sinon idle
    self.state = "idle"
end

function Enemy:act(dt, player)
    if self.hitStunTimer > 0 then
        return
    end

    if self.state == "idle" then
        self:idleBehavior(dt)
    elseif self.state == "freeze" then
        return
    elseif self.state == "chase" then
        self:chaseBehavior(dt, player)
        self:tryAttack(player)
    elseif self.state == "search" then
        self:searchBehavior(dt)
    end
end

---------------------
--- Comportements ---
---------------------
function Enemy:idleBehavior(dt)
    self.angle = self.angle + dt * 0.5
end

function Enemy:chaseBehavior(dt, player)
    local toPlayer = player.pos - self.pos
    local dist = toPlayer:len()

    -- Si trop proche → on s'arrête
    if dist <= self.stopDistance then
        return
    end

    local dir = toPlayer:normalized()
    self.angle = math.atan2(dir.y, dir.x)

    local velocity = dir * self.speed * dt
    local goal = self.pos + velocity

    local ax, ay = self.world:move(self, goal.x, goal.y, WorldUtils.enemyFilter)
    MathUtils.updateCoordinates(self, ax, ay)
    self.level.spatialHash:update(self)
end

function Enemy:searchBehavior(dt)
    local target = self.lastSeenPlayerPos or self.lastHeardNoisePos
    if not target then
        return
    end

    -- Déplacement simple vers la target (tu peux remplacer par ton move habituel)
    local dir = (target - self.pos)
    local dist = dir:len()

    -- arrivé
    if dist < 8 then
        return
    end

    dir = dir:normalized()
    local goalX = self.x + dir.x * self.speed * 0.6 * dt
    local goalY = self.y + dir.y * self.speed * 0.6 * dt

    -- collision bump
    local actualX, actualY = self.world:move(self, goalX, goalY, function() return "slide" end)
    self.x, self.y = actualX, actualY
    self.pos.x, self.pos.y = self.x, self.y

    -- regarde vers la target
    self.angle = math.atan2(target.y - (self.y + self.h/2), target.x - (self.x + self.w/2))
end

function Enemy:tryAttack(player)
    if self.attackTimer > 0 then return end

    local cx, cy = self:getCenter()
    local px, py = player:getCenter()

    local toPlayer = Vector(px - cx, py - cy)
    local dist = toPlayer:len()

    if dist > self.attackRange then
        return
    end

    local forward = Vector(math.cos(self.angle), math.sin(self.angle))
    local dir = toPlayer:normalized()

    local dot = forward.x * dir.x + forward.y * dir.y
    local maxDot = math.cos(self.attackAngle / 2)

    if dot < maxDot then
        return
    end

    -- 💥 TOUCHE
    player:takeDamage(self.attackDamage)

    self.attackTimer = self.attackCooldown
    self.attackFlashTime = 0.15

    --self.pos = self.pos - Vector(math.cos(self.angle), math.sin(self.angle)) * 20
    --MathUtils.updateCoordinates(self, self.pos.x, self.pos.y)
end

function Enemy:onHit(damage, fromAngle)
    -- Dégâts
    self.hp = self.hp - damage
    if self.hp <= 0 then
        self.state = "dead"
        return
    end

    -- ⏸️ CUT D’ÉLAN
    self.hitStunTimer = self.hitStunDuration

    -- ↩️ Recul léger
    local knockback = Vector(math.cos(fromAngle), math.sin(fromAngle)) * 16
    local bx, by = self.world:move(
            self,
            self.pos.x + knockback.x,
            self.pos.y + knockback.y,
            WorldUtils.enemyFilter
    )
    MathUtils.updateCoordinates(self, bx, by)
    self.level.spatialHash:update(self)
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

    if self.attackFlashTime > 0 then
        local cx, cy = self:getCenter()

        love.graphics.setColor(1, 0, 0, 0.4)
        love.graphics.arc(
                "fill",
                cx,
                cy,
                self.attackRange,
                self.angle - self.attackAngle / 2,
                self.angle + self.attackAngle / 2,
                16
        )
    end

    if DEBUG_MODE then
        self:debug()
    end

    love.graphics.setColor(1, 1, 1)
end

function Enemy:canSee(player)
    local toPlayer = player.pos - self.pos
    local dist = toPlayer:len()

    if dist > self.visionRange then
        return false
    end

    local forward = Vector(math.cos(self.angle), math.sin(self.angle))
    local dir = toPlayer:normalized()

    local dot = forward.x * dir.x + forward.y * dir.y
    local maxDot = math.cos(self.fov / 2)

    if dot < maxDot then
        return false
    end

    -- LOS précis : ENEMY -> points sur le PLAYER
    local ex, ey = self:getCenter()

    local pw, ph = player.w or 0, player.h or 0
    local ox = math.min(4, pw * 0.25)
    local oy = math.min(4, ph * 0.25)

    local points = {
        { player.x + pw * 0.5, player.y + ph * 0.5 }, -- centre
        { player.x + ox,       player.y + oy },
        { player.x + pw - ox,  player.y + oy },
        { player.x + ox,       player.y + ph - oy },
        { player.x + pw - ox,  player.y + ph - oy },
    }

    for _, p in ipairs(points) do
        if VisionUtils.hasLineOfSight(self.level, ex, ey, p[1], p[2], 1.0) then
            return true
        end
    end

    return false
end

function Enemy:onNoiseHeard(x, y, strength)
    -- strength: 0..1 (pour plus tard)
    self.lastHeardNoisePos = Vector(x, y)
    self.timeSinceHeard = 0

    -- Si je ne vois pas déjà le joueur, je vais investiguer
    if self.state ~= "chase" then
        self.state = "search"
    end
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
    local cx = self.x + self.w / 2
    local cy = self.y + self.h / 2

    love.graphics.setColor(1, 1, 0, 0.15)

    love.graphics.arc(
            "fill",
            cx, cy,
            self.visionRange,
            self.angle - self.fov / 2,
            self.angle + self.fov / 2,
            32
    )

    -- Direction
    love.graphics.setColor(self.canSeePlayer and 0 or 1, self.canSeePlayer and 1 or 0, 0)
    love.graphics.line(
            cx, cy,
            cx + math.cos(self.angle) * self.visionRange,
            cy + math.sin(self.angle) * self.visionRange
    )

    -- Infos
    love.graphics.print(
            string.format(
                    "state: %s\ncanSee: %s",
                    self.state,
                    tostring(self.canSeePlayer)
            ),
            self.x,
            self.y - 55
    )

    -- Point central
    love.graphics.setColor(0.8, 0, 0, 0.8)
    love.graphics.circle("line", cx, cy, self.visionRange)

    -- Hitbox Bump (en blanc)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
end

return Enemy