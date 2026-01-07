-- Dependancies
local Enemy = require "src.entities.enemies.Enemy"
local Vector = require "libs.hump.vector"
-- Utils
local WorldUtils = require "src.utils.world_utils"
local MathUtils = require "src.utils.math_utils"

local Chaser = Enemy:extend()

function Chaser:new(world, level, seed, x, y)
    -- HP: 3, Speed: 80
    Chaser.super.new(self, world, level, seed, x, y)
    self.hp = 3
    self.maxHp = self.hp
    self.speed = 80
    self.type = "chaser"
    self.color = {
        red = 1,
        green = 0,
        blue = 0,
        alpha = 1
    }

    -- Idle properties
    self.idleAxis = (self.rng:random() < 0.5) and "horizontal" or "vertical"
    self.idleDir  = (self.rng:random() < 0.5) and -1 or 1
    self.idleSpeed = self.speed * 0.4
    -- Patrol
    -- Distance de patrouille idle
    self.idlePatrolMin = 96 -- en pixels
    self.idlePatrolMax = 192
    self.idlePatrolMaxDist = 0
    self.idlePatrolDist = 0
    -- Pause
    self.idlePauseTimer = 0
    self.idlePauseMin = 2.0
    self.idlePauseMax = 4.0
    -- Scan
    self.idleScanDir = (self.rng:random() < 0.5) and -1 or 1
    self.idleScanSpeed = 1.2 -- vitesse de balayage
    self.idleScanAngle = math.rad(15) -- amplitude gauche/droite
    self.idleScanPhase = 0

    self:_resetIdlePatrolDistance()
end

function Chaser:onStateEnter(newState, oldState)
    if newState == "idle" and oldState ~= "idle" then
        self:_resetIdlePattern()
        self:_resetIdlePatrolDistance()
        -- Reset du temps de pause
        self.idlePauseTimer = 0
    end
end

function Chaser:idleBehavior(dt)
    local dxBase, dyBase, baseAngle = self:_getIdleBaseVector()

    -- PAUSE : pas de déplacement, rotation de scan
    if self.idlePauseTimer > 0 then
        self.idlePauseTimer = self.idlePauseTimer - dt

        -- Oscillation gauche / droite
        self.idleScanPhase = self.idleScanPhase + dt * self.idleScanSpeed
        local scanOffset = math.sin(self.idleScanPhase) * self.idleScanAngle * self.idleScanDir

        self.angle = baseAngle + scanOffset

        if self.idlePauseTimer <= 0 then
            self:_stopIdlePause()
        end

        return
    end

    -- DÉPLACEMENT NORMAL
    local dx = dxBase * self.idleSpeed * dt
    local dy = dyBase * self.idleSpeed * dt
    self.angle = baseAngle

    local goalX = self.x + dx
    local goalY = self.y + dy

    local actualX, actualY, cols, len =
    self.world:move(self, goalX, goalY, WorldUtils.enemyFilter)

    -- Distance réellement parcourue
    local movedDx = actualX - self.x
    local movedDy = actualY - self.y
    local movedDist = math.sqrt(movedDx * movedDx + movedDy * movedDy)

    MathUtils.updateCoordinates(self, actualX, actualY)
    self.level.spatialHash:update(self)

    -- Accumulation distance
    self.idlePatrolDist = self.idlePatrolDist + movedDist

    -- FIN DE PATROUILLE : distance OU collision
    if self.idlePatrolDist >= self.idlePatrolMaxDist or (len and len > 0) then
        self.idleDir = -self.idleDir
        self.idleScanPhase = 0
        self:_startIdlePause()
    end
end

function Chaser:_getIdleBaseVector()
    if self.idleAxis == "horizontal" then
        return self.idleDir, 0, (self.idleDir == 1) and 0 or math.pi
    else
        return 0, self.idleDir, (self.idleDir == 1) and math.pi / 2 or -math.pi / 2
    end
end

function Chaser:_startIdlePause()
    self.idlePauseTimer = self.rng:random() * (self.idlePauseMax - self.idlePauseMin) + self.idlePauseMin
end

function Chaser:_stopIdlePause()
    -- Probabilité de changer d’axe
    if self.rng:random() < 0.4 then
        self.idleAxis =
        (self.idleAxis == "horizontal") and "vertical" or "horizontal"
    end

    -- Probabilité de changer de sens
    if self.rng:random() < 0.5 then
        self.idleDir = -self.idleDir
    end

    -- Reset du scan
    self.idleScanPhase = 0
    self.idleScanDir =
    (self.rng:random() < 0.5) and -1 or 1

    self:_resetIdlePatrolDistance()
end

function Chaser:_resetIdlePattern()
    if self.rng:random() < 0.7 then
        -- garde l'axe
    else
        self.idleAxis = (self.idleAxis == "horizontal") and "vertical" or "horizontal"
    end

    self.idleDir = (self.rng:random() < 0.5) and -1 or 1
end

function Chaser:_resetIdlePatrolDistance()
    self.idlePatrolMaxDist = self.rng:random(self.idlePatrolMin, self.idlePatrolMax)
    self.idlePatrolDist = 0
end

return Chaser