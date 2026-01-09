local Theme = Class:extend()

function Theme:new(level, seed)
    self.level = level
    self.rng = love.math.newRandomGenerator(seed)
    --self.map = level.map
end

-- Structure du niveau par défaut
function Theme:getProfile()
    return {}
end

function Theme:getPuzzles()
    return {}
end

-- Décoration après génération
function Theme:decorate(level)
    -- optionnel
end

return Theme
