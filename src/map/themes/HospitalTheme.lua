local Theme = require "src.map.themes.Theme"
local MapUtils = require "src.utils.map_utils"

local HospitalTheme = Theme:extend()

HospitalTheme.NAME = "Hôpital"

function HospitalTheme:new(level)
    HospitalTheme.super.new(self, level)

    self.id = "hospital"

    -- Réglages verre
    self.glassChancePerRoom = 0.75    -- 75% des rooms ont du verre
    self.glassPatchesMin = 1
    self.glassPatchesMax = 3
    self.patchWMin = 2
    self.patchWMax = 5
    self.patchHMin = 2
    self.patchHMax = 4

    -- Évite les murs internes + bordures
    self.glassMargin = 3
end

-- Appelé pour CHAQUE room
function HospitalTheme:generateRoom(room)
    -- 1) Garde le comportement de base (murs internes)
    Theme.generateRoom(self, room)

    -- 2) Ajoute le verre
    self:_generateGlass(room)
end

function HospitalTheme:_generateGlass(room)
    if self.rng:random() > self.glassChancePerRoom then
        return
    end

    local map = self.map
    local rect = room.rect

    -- room trop petite
    if rect.w < 8 or rect.h < 8 then
        return
    end

    local patches = self.rng:random(self.glassPatchesMin, self.glassPatchesMax)

    for _ = 1, patches do
        local pw = self.rng:random(self.patchWMin, self.patchWMax)
        local ph = self.rng:random(self.patchHMin, self.patchHMax)

        local minX = rect.x + self.glassMargin
        local minY = rect.y + self.glassMargin
        local maxX = rect.x + rect.w - self.glassMargin - pw
        local maxY = rect.y + rect.h - self.glassMargin - ph

        if minX >= maxX or minY >= maxY then
            break
        end

        local sx = self.rng:random(minX, maxX)
        local sy = self.rng:random(minY, maxY)

        for ty = sy, sy + ph do
            for tx = sx, sx + pw do
                -- uniquement sur sol normal (1), jamais sur mur (2) ni déjà verre
                if map[ty] and MapUtils:isWalkableTile(map, tx, ty) then
                    map[ty][tx] = 4 -- verre
                end
            end
        end
    end
end

return HospitalTheme