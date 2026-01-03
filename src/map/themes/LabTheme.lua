local Theme = require "src.map.themes.Theme"

local LabTheme = Theme:extend()

function LabTheme:generateRoom(room)
    -- 1 chance sur 2
    if self.rng:random() < 0.5 then
        self:_generatePillarRectangle(room)
    end
end

-- Pattern spécifique LAB
function LabTheme:_generatePillarRectangle(room)
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
            self.map[ty][tx] = 3
        end
    end
end

function LabTheme:_canPlacePillar(tx, ty)
    -- doit être du sol
    if self.map[ty][tx] ~= 1 then
        return false
    end

    -- pas collé à un mur
    if self.map[ty-1][tx] == 2 or self.map[ty+1][tx] == 2
       or self.map[ty][tx-1] == 2 or self.map[ty][tx+1] == 2 then
        return false
    end

    return true
end

return LabTheme
