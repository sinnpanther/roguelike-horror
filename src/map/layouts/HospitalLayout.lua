local Room = require "src.map.Room"

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
    self:_createMainCorridor()
end

--------------------------------------------------
-- GLOBAL POSITIONING
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

        self:_carveRoom(rect)

        local roomSeed = self.rng:random(1, 2^30)
        table.insert(level.rooms, Room(level.world, level, roomSeed, level.levelIndex, rect))

        cursorX = cursorX + data.w + self.roomSpacing
    end
end

--------------------------------------------------
-- MAIN CORRIDOR
--------------------------------------------------
function HospitalLayout:_createMainCorridor()
    local map = self.map
    local rooms = self.level.rooms
    local profile = self.profile

    if #rooms == 0 then
        return
    end

    local extra = self.rng:random(
            profile.corridorExtraLength.min,
            profile.corridorExtraLength.max
    )

    local fromX = rooms[1].rect.x - extra
    local last = rooms[#rooms]
    local toX = last.rect.x + last.rect.w - 1 + extra

    fromX = math.max(1, fromX)
    toX = math.min(self.level.mapW - 1, toX)

    local width = profile.corridorWidth or 2

    for y = self.corridorY, self.corridorY + width - 1 do
        for x = fromX, toX do
            map[y][x] = TILE_CORRIDOR
        end
    end

    for _, room in ipairs(rooms) do
        self:_connectRoomToCorridor(room)
    end
end

--------------------------------------------------
-- ROOM → CORRIDOR CONNECTION
--------------------------------------------------
function HospitalLayout:_connectRoomToCorridor(room)
    local map = self.map
    local doorX = math.floor(room.rect.x + room.rect.w / 2)

    local fromY, toY

    if self.corridorSide == "top" then
        fromY = self.corridorY + self.profile.corridorWidth
        toY = room.rect.y
    else
        fromY = room.rect.y + room.rect.h
        toY = self.corridorY
    end

    for y = fromY, toY do
        map[y][doorX] = TILE_FLOOR
        map[y][doorX + 1] = TILE_FLOOR
    end
end

--------------------------------------------------
-- CARVING
--------------------------------------------------
function HospitalLayout:_carveRoom(rect)
    local map = self.map

    for y = rect.y, rect.y + rect.h - 1 do
        for x = rect.x, rect.x + rect.w - 1 do
            map[y][x] = TILE_FLOOR
        end
    end
end

return HospitalLayout
