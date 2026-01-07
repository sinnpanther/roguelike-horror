local Theme = require "src.map.themes.Theme"
local MapUtils = require "src.utils.map_utils"

local HospitalTheme = Theme:extend()

HospitalTheme.ID = "hospital"
HospitalTheme.NAME = "Hôpital"

function HospitalTheme:getProfile()
    return {
        layout = self.ID,
        roomShape = "rect",

        roomCount = { min = 4, max = 5 },
        roomWidth = { min = 16, max = 20 },
        roomHeight = { min = 13, max = 16 },
        roomSpacing = 6,
        roomGapFromCorridor = 3,

        hasCorridors = true,
        corridorWidth = 3,
        corridorExtraLength = { min = 4, max = 10 },

        hasOuterWalls = true,

        hasInternalWalls = false,
        internalWallChance = 0,

        hasPillars = false,
        pillarChance = 0,

        hasProps = false,
        propChance = 0,

        hasEnemies = true,
        enemyChance = 0.75,

        glassChancePerRoom = 0.1
    }
end

--------------------------------------------------
-- Décoration spécifique Hôpital
--------------------------------------------------
function HospitalTheme:decorate(room)
    self:_generateGlass(room)
end

--------------------------------------------------
-- Verre
--------------------------------------------------
function HospitalTheme:_generateGlass(room)
    local map = room.level.map
    local rect = room.rect
    local rng = room.rng
    local profile = self:getProfile()

    if rng:random() > profile.glassChancePerRoom then
        return
    end

    -- room trop petite
    if rect.w < 8 or rect.h < 8 then
        return
    end

    local patches = rng:random(1, 3)
    local margin = 3

    for _ = 1, patches do
        local pw = rng:random(2, 5)
        local ph = rng:random(2, 4)

        local minX = rect.x + margin
        local minY = rect.y + margin
        local maxX = rect.x + rect.w - margin - pw
        local maxY = rect.y + rect.h - margin - ph

        if minX >= maxX or minY >= maxY then
            break
        end

        local sx = rng:random(minX, maxX)
        local sy = rng:random(minY, maxY)

        for ty = sy, sy + ph do
            for tx = sx, sx + pw do
                if map[ty] and MapUtils:isWalkableTile(map, tx, ty) then
                    map[ty][tx] = TILE_GLASS
                end
            end
        end
    end
end

return HospitalTheme
