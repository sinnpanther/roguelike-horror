-- Dependancies
local Enemy = require "src.entities.enemies.Enemy"
local Vector = require "libs.hump.vector"
-- Utils
local WorldUtils = require "src.utils.world_utils"
local MathUtils = require "src.utils.math_utils"

local Watcher = Enemy:extend()

function Watcher:new(world, level, x, y)
    Watcher.super.new(self, world, level, x, y)

    self.pos = Vector(x, y)
    self.hp = 3
    self.maxHp = self.hp
    self.speed = 40
    self.type = "watcher"
    self.color = {
        red = 0,
        green = 1,
        blue = 0,
        alpha = 1
    }
end

--function Watcher:perceive(player)
--    Watcher.super.perceive(self, player)
--
--    if player:canSee(self) then
--        self.lastSeenPlayerPos = player.pos:clone()
--        self.timeSinceLastSeen = 0
--        self.seen = true
--    else
--        self.seen = false
--        self.timeSinceLastSeen = self.timeSinceLastSeen + love.timer.getDelta()
--    end
--end

function Watcher:updateState(dt, player)
    if player:canSee(self) then
        self.state = "freeze"
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
        return
    end

    self.state = "idle"
end

function Watcher:act(dt, player)
    if self.state == "freeze" then
        -- Immobilité totale
        return
    end

    if self.state == "chase" then
        self:chaseBehavior(dt, player)
    end
end

function Watcher:chaseBehavior(dt, player)
    local dir = (player.pos - self.pos)
    if dir:len() < 1 then return end

    dir = dir:normalized()
    self.angle = math.atan2(dir.y, dir.x)

    local velocity = dir * self.speed * dt
    local goal = self.pos + velocity

    local ax, ay = self.world:move(self, goal.x, goal.y, WorldUtils.enemyFilter)
    MathUtils.updateCoordinates(self, ax, ay)
    self.level.spatialHash:update(self)
end

return Watcher
