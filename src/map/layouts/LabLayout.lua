-- Dependancies
local Room = require "src.map.Room"
local Corridor = require "src.map.Corridor"
local Pillar = require "src.map.props.Pillar"
-- Utils
local MapUtils = require "src.utils.map_utils"

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
    if self.profile.hasPillars then
        self:_placeProps()
    end
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

        -- Zone centrale plus dense
        local marginX = math.floor(self.mapW * 0.25)
        local marginY = math.floor(self.mapH * 0.25)

        local w = self.rng:random(profile.roomWidth.min, profile.roomWidth.max)
        local h = self.rng:random(profile.roomHeight.min, profile.roomHeight.max)
        local x = self.rng:random(marginX, self.mapW - marginX - w)
        local y = self.rng:random(marginY, self.mapH - marginY - h)

        local rect = { x = x, y = y, w = w, h = h }

        if not self:_rectOverlapsAny(rect, 3) then
            local roomSeed = self.rng:random(1, 2^30)
            local room = Room(self.world, self.level, roomSeed, profile, rect)
            table.insert(self.level.rooms, room)
            room:carve(profile)
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

function LabLayout:_placeProps()
    for _, room in ipairs(self.level.rooms) do
        self:generatePillars(room)
        self:_buildPillars(room)
    end
end

function LabLayout:generatePillars(room)
    local profile = self.profile

    if not profile.hasPillars then
        return
    end

    if self.rng:random() > profile.pillarChance then
        return
    end

    if room.rect.w < 8 or room.rect.h < 8 then
        return
    end

    local margin = 4

    local left   = room.rect.x + margin
    local right  = room.rect.x + room.rect.w - margin - 1
    local top    = room.rect.y + margin
    local bottom = room.rect.y + room.rect.h - margin - 1

    local positions = {
        { left,  top },
        { right, top },
        { left,  bottom },
        { right, bottom },
    }

    for _, p in ipairs(positions) do
        local tx, ty = p[1], p[2]
        if self:_canPlacePillar(tx, ty) then
            self.level.map[ty][tx] = TILE_PROP
        end
    end
end

function LabLayout:_canPlacePillar(tx, ty)
    local map = self.level.map

    -- Si ce n'est pas une tile acceptable
    if not MapUtils:isWalkableTile(map, tx, ty) then
        return false
    end

    return true
end

function LabLayout:_buildPillars(room)
    local level = self.level
    level.props = level.props or {}

    for y = room.rect.y, room.rect.y + room.rect.h - 1 do
        for x = room.rect.x, room.rect.x + room.rect.w - 1 do
            if level.map[y][x] == TILE_PROP then
                table.insert(level.props, Pillar(self.world, x, y, { theme = level.theme }))
            end
        end
    end
end

return LabLayout
