-- src/entities/map/Level.lua
local Room = require "src.entities.map.Room"

local Level = Class:extend()

function Level:new(world, seed, levelIndex)
    self.world = world
    self.seed  = seed
    self.levelIndex = levelIndex
    self.segments = {}
end

function Level:generate()
    -- Pour l'instant, une seule Room comme avant
    local room = Room(self.world, self.seed, self.levelIndex)
    room:generate()
    table.insert(self.segments, room)
    self.mainRoom = room
end

function Level:update(dt, player)
    -- Update des ennemis de toutes les rooms
    for _, seg in ipairs(self.segments) do
        for _, enemy in ipairs(seg.enemies) do
            enemy:update(dt, player)
        end
    end
end

function Level:draw(player)
    for _, seg in ipairs(self.segments) do
        seg:draw()
    end
    -- Pas de plafond pour l'instant
end

return Level