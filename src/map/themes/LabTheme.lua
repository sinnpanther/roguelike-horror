local Theme = require "src.map.themes.Theme"

local LabTheme = Theme:extend()

LabTheme.ID = "laboratory"
LabTheme.NAME = "Laboratoire"

function LabTheme:getProfile()
    return {
        layout = self.ID,

        roomShape = "rect",
        roomCount = { min = 4, max = 7 },
        roomWidth = { min = 20, max = 28 },
        roomHeight = { min = 18, max = 24 },

        hasCorridors = true,
        corridorWidth = 2,

        hasOuterWalls = true,
        hasInternalWalls = true,
        internalWallChance = 0.6,

        hasPillars = true,
        pillarChance = 0.5,

        hasProps = false,
        propChance = 0,

        hasEnemies = true,
        enemyChance = 0.8,
    }
end

function LabTheme:decorate(room)

end

return LabTheme
