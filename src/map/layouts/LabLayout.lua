-- src/map/layouts/LabLayout.lua
local Room = require "src.map.Room"
local Corridor = require "src.map.Corridor"

local LabLayout = Class:extend()

function LabLayout:new(level, profile, seed)
    self.level = level
    self.world = level.world
    self.map = level.map
    self.profile = profile
    self.rng = love.math.newRandomGenerator(seed)
    self.mapW = level.mapW
    self.mapH = level.mapH
end

function LabLayout:build()
    self:_createRooms()
    self:_createCorridors()
end

--------------------------------------------------
-- ROOMS
--------------------------------------------------
function LabLayout:_createRooms()
    local profile = self.profile

    local roomCount = self.rng:random(profile.roomCount.min, profile.roomCount.max)
    self:_placeRooms(roomCount)
end

function LabLayout:_placeRooms(roomCount)
    local profile = self.profile
    local maxAttempts = roomCount * 40
    local attempts = 0

    while #self.level.rooms < roomCount and attempts < maxAttempts do
        attempts = attempts + 1

        local w = self.rng:random(20, 28)
        local h = self.rng:random(18, 24)
        -- Zone centrale plus dense
        local marginX = math.floor(self.mapW * 0.25)
        local marginY = math.floor(self.mapH * 0.25)

        local x = self.rng:random(marginX, self.mapW - marginX - w)
        local y = self.rng:random(marginY, self.mapH - marginY - h)

        local rect = { x = x, y = y, w = w, h = h }

        if not self:_rectOverlapsAny(rect, 3) then
            local roomSeed = self.rng:random(1, 2^30)
            local room = Room(self.world, self.level, roomSeed, profile, rect)
            room:carve(profile)
            table.insert(self.level.rooms, room)
        end
    end
end

function LabLayout:_rectOverlapsAny(rect, padding)
    for _, r in ipairs(self.level.rooms) do
        local a = rect
        local b = r.rect
        if self:_rectsOverlap(a, b, padding) then
            return true
        end
    end
    return false
end

function LabLayout:_rectsOverlap(a, b, padding)
    local p = padding or 0
    return not (
            a.x + a.w + p < b.x or
                    a.x > b.x + b.w + p or
                    a.y + a.h + p < b.y or
                    a.y > b.y + b.h + p
    )
end

function LabLayout:_carveRoom(rect)
    for y = rect.y, rect.y + rect.h - 1 do
        for x = rect.x, rect.x + rect.w - 1 do
            self.map[y][x] = TILE_FLOOR -- sol
        end
    end
end

function LabLayout:_createCorridors()
    local corridorSeed = self.rng:random(1, 2^30)
    local corridor = Corridor(corridorSeed, self.level, self.profile)

    corridor:build()
end

return LabLayout
