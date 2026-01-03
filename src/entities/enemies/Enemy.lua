local Vector = require "libs.hump.vector"
local MathUtils = require "src.utils.math_utils"
local WorldUtils = require "src.utils.world_utils"

local Enemy = Class:extend()

function Enemy:new(world, level, x, y)
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

    self.vx = 0
    self.vy = 0

    -- State machine
    self.state = "idle"
    self.canSeePlayer = nil

    self.visionRange = 250
    self.fov = math.rad(80)
    self.angle = 0

    self.lastSeenPlayerPos = nil
    self.timeSinceLastSeen = math.huge

    -- Ajout au monde physique
    self.world:add(self, self.x, self.y, self.w, self.h)
end

-- Méthode à redéfinir par les enfants (l'IA)
function Enemy:update(dt, player)
    self:perceive(player)
    self:updateState(dt, player)
    self:act(dt, player)
end

function Enemy:perceive(player)
    if self:canSee(player) then
        self.lastSeenPlayerPos = player.pos:clone()
        self.timeSinceLastSeen = 0
        self.canSeePlayer = true
    else
        self.canSeePlayer = false
        self.timeSinceLastSeen = self.timeSinceLastSeen + love.timer.getDelta()
    end
end

function Enemy:updateState(dt, player)
    if self.state == "dead" then
        return
    end

    if self.lastSeenPlayerPos then
        if self.timeSinceLastSeen < 0.5 then
            self.state = "chase"
        elseif self.timeSinceLastSeen < 3 then
            self.state = "search"
        else
            self.lastSeenPlayerPos = nil
            self.state = "idle"
        end
    end
end

function Enemy:act(dt, player)
    if self.state == "idle" then
        self:idleBehavior(dt)
    elseif self.state == "freeze" then
        return
    elseif self.state == "chase" then
        self:chaseBehavior(dt, player)
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
    error("You must implement this method (chaseBehavior).")
end

function Enemy:searchBehavior(dt)
    -- Se diriger vers la dernière position connue
    -- Regarder autour
    -- Avancer lentement
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

    return dot >= maxDot
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