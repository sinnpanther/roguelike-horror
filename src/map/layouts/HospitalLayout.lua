local Room = require "src.map.Room"
local Corridor = require "src.map.Corridor"

local HospitalLayout = Class:extend()

function HospitalLayout:new(level, profile, seed)
    self.level = level
    self.profile = profile
    self.rng = love.math.newRandomGenerator(seed)
    self.map = level.map
end

--------------------------------------------------
-- ENTRY POINT
--------------------------------------------------
function HospitalLayout:build()
    self:_computeCorridorPosition()
    self:_createRooms()
    self:_createCorridor()
end

--------------------------------------------------
-- ROOMS
--------------------------------------------------
function HospitalLayout:_createRooms()
    local level = self.level
    local mapW = level.mapW
    local profile = self.profile

    local roomCount = self.rng:random(
            profile.roomCount.min,
            profile.roomCount.max
    )

    -- Génération des tailles AVANT placement
    self.roomRects = {}
    local totalWidth = 0

    for i = 1, roomCount do
        local w = self.rng:random(profile.roomWidth.min, profile.roomWidth.max)
        local h = self.rng:random(profile.roomHeight.min, profile.roomHeight.max)

        table.insert(self.roomRects, {
            w = w,
            h = h
        })

        totalWidth = totalWidth + w
        if i < roomCount then
            totalWidth = totalWidth + self.roomSpacing
        end
    end

    local startX = math.floor((mapW - totalWidth) / 2)

    local cursorX = startX

    for i, data in ipairs(self.roomRects) do
        local roomY

        if self.corridorSide == "top" then
            roomY = self.corridorY + self.profile.corridorWidth + self.roomGapFromCorridor
        else
            roomY = self.corridorY - data.h - self.roomGapFromCorridor
        end

        local rect = {
            x = cursorX,
            y = roomY,
            w = data.w,
            h = data.h
        }

        local roomSeed = self.rng:random(1, 2^30)
        local room = Room(level.world, level, roomSeed, profile, rect)
        table.insert(level.rooms, room)
        room:carve()

        cursorX = cursorX + data.w + self.roomSpacing
    end
end

--------------------------------------------------
-- Corridor
--------------------------------------------------
function HospitalLayout:_computeCorridorPosition()
    local mapH = self.level.mapH

    self.corridorSide = self.rng:random() < 0.5 and "top" or "bottom"

    if self.corridorSide == "top" then
        self.corridorY = math.floor(mapH * 0.20)
    else
        self.corridorY = math.floor(mapH * 0.65)
    end

    self.roomSpacing = self.profile.roomSpacing or 6
    self.roomGapFromCorridor = self.profile.roomGapFromCorridor or 3
end

function HospitalLayout:_createCorridor()
    local data = { y = self.corridorY, side = self.corridorSide }
    local corridorSeed = self.rng:random(1, 2^30)
    local corridor = Corridor(corridorSeed, self.level, self.profile, data)

    corridor:build()
end

return HospitalLayout
