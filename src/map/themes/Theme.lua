local Theme = Class:extend()

function Theme:new(level, seed)
    self.level = level
    self.rng = love.math.newRandomGenerator(seed)
    --self.map = level.map
end

-- Structure du niveau par défaut
function Theme:getProfile()
    return {
        roomCount = { min = 3, max = 6 },

        layout = "chain", -- chain | hub | tree | arena
        roomShape = "rect", -- rect | organic | blob | single
        hasCorridors = true,
        corridorWidth = 2,

        hasOuterWalls = true, -- murs autour des rooms
        hasInternalWalls = true, -- murs internes possibles
        internalWallChance = 0.5,

        hasPillars = true,
        pillarChance = 0.5,

        hasProps = true,
        propChance = 0.6,

        hasEnemies = true,
        enemyChance = 0.5,

        lighting = "normal",        -- plus tard
    }
end

-- Décoration après génération
function Theme:decorate(level)
    -- optionnel
end

return Theme
