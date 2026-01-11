local PuzzleBase = require "src.puzzles.PuzzleBase"
local MapUtils = require "src.utils.map_utils"
local Target = require "src.entities.targets.Target"

local LightAnglePuzzle = PuzzleBase:extend()

function LightAnglePuzzle:new(level, seed)
    LightAnglePuzzle.super.new(self, level, seed)

    self.activationDelay = 2.0
    self.active = false
end

function LightAnglePuzzle:setup()
    local rooms = self.level.rooms

    self.targets = {}

    local count = #rooms

    for i = 1, count do
        local room = rooms[i]
        local tx, ty = MapUtils.getRandomPointInRoom(self.level, room, self.rng)
        table.insert(self.targets, Target(tx, ty, 16, 16, {
            angle = self.rng:random() * math.pi * 2,
            activated = false,
            timer = 0
        }))
    end
end

function LightAnglePuzzle:update(dt, player)
    for _, t in ipairs(self.targets) do
        if player:canSee(t) then
            t.timer = t.timer + dt
            if t.timer >= self.activationDelay then
                t.activated = true
            end
        else
            t.timer = 0
        end
    end
end

function LightAnglePuzzle:checkSolved()
    for _, t in ipairs(self.targets) do
        if not t.activated then
            return false
        end
    end

    return true
end

function LightAnglePuzzle:draw()
    for _, t in ipairs(self.targets) do
        if not t.activated then
            love.graphics.setColor(1, 1, 0, 1)
        else
            love.graphics.setColor(0, 1, 0, 1)
        end


        love.graphics.circle("line", t.pos.x, t.pos.y, 18)
    end
    love.graphics.setColor(1,1,1)
end

return LightAnglePuzzle
