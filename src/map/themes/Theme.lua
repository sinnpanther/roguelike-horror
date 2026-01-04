local MapUtils = require "src.utils.map_utils"

local Theme = Class:extend()

function Theme:new(level)
    self.level = level
    self.rng = level.rng
    self.map = level.map
end

function Theme:generate()
    for _, room in ipairs(self.level.rooms) do
        self:generateRoom(room)
    end
end

-- Appelé pour CHAQUE room
function Theme:generateRoom(room)
    -- 1 chance sur 2 pour un renfoncement
    if self.rng:random() < 0.5 then
        self:_generateInternalWall(room)
    end
end

function Theme:_generateInternalWall(room)
    -- room trop petite
    if room.rect.w < 10 or room.rect.h < 10 then
        return
    end

    -- orientation du mur
    local orientation = self.rng:random(1, 2)
    -- 1 = horizontal, 2 = vertical

    if orientation == 1 then
        self:_generateHorizontalWall(room)
    else
        self:_generateVerticalWall(room)
    end
end

function Theme:_generateHorizontalWall(room)
    local map = self.map

    local wallThickness = 2
    local wallMargin = 4

    -- Y possible UNIQUEMENT dans la zone safe
    local minY = room.rect.y + wallMargin
    local maxY = room.rect.y + room.rect.h - wallThickness - wallMargin

    if minY >= maxY then
        return
    end

    local y = self.rng:random(minY, maxY)

    -- Le mur part d’un côté mais pas trop loin
    local fromLeft = self.rng:random() < 0.5

    local minX = room.rect.x + wallMargin
    local maxX = room.rect.x + room.rect.w - wallMargin - 1

    local startX, endX

    if fromLeft then
        startX = room.rect.x
        endX   = self.rng:random(
                minX + 2,
                math.floor(room.rect.x + room.rect.w * 0.6)
        )
    else
        startX = self.rng:random(
                math.floor(room.rect.x + room.rect.w * 0.4),
                maxX - 2
        )
        endX = room.rect.x + room.rect.w - 1
    end

    for ty = y, y + wallThickness - 1 do
        for tx = startX, endX do
            if MapUtils:isWalkableTile(map, tx, ty) then
                map[ty][tx] = 2
            end
        end
    end
end

function Theme:_generateVerticalWall(room)
    local map = self.map

    local wallThickness = 2
    local wallMargin = 4

    local minX = room.rect.x + wallMargin
    local maxX = room.rect.x + room.rect.w - wallThickness - wallMargin

    if minX >= maxX then
        return
    end

    local x = self.rng:random(minX, maxX)

    local minY = room.rect.y + wallMargin
    local maxY = room.rect.y + room.rect.h - wallMargin - 1

    local fromTop = self.rng:random() < 0.5

    local startY, endY

    if fromTop then
        startY = room.rect.y
        endY   = self.rng:random(
                minY + 2,
                math.floor(room.rect.y + room.rect.h * 0.6)
        )
    else
        startY = self.rng:random(
                math.floor(room.rect.y + room.rect.h * 0.4),
                maxY - 2
        )
        endY = room.rect.y + room.rect.h - 1
    end

    for tx = x, x + wallThickness - 1 do
        for ty = startY, endY do
            if MapUtils:isWalkableTile(map, tx, ty) then
                map[ty][tx] = 2
            end
        end
    end
end

return Theme
