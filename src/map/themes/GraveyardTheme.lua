local Theme = require "src.map.themes.Theme"

local GraveyardTheme = Theme:extend()

GraveyardTheme.ID = "graveyard"
GraveyardTheme.NAME = "Cimetière"

function GraveyardTheme:getProfile()
    return {
        layout = self.ID,

        roomShape = "organic",
        roomCount = 1,
        --roomWidth = { min = 45, max = 50 },
        --roomHeight = { min = 20, max = 25 },
        roomWidth  = { min = 65, max = 70 },
        roomHeight = { min = 40, max = 45 },

        erosionDepth = 4,

        hasCorridors = false,
        corridorWidth = 2,

        hasOuterWalls = true,
        hasInternalWalls = false,
        internalWallChance = 0,

        hasProps = true,
        propChance = 0.4,

        hasEnemies = true,
        enemyChance = 0.8,

        hasPuzzle = false,
    }
end

function GraveyardTheme:decorate(room)

end

return GraveyardTheme