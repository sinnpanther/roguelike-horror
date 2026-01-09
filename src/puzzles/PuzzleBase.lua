local PuzzleBase = Class:extend()

function PuzzleBase:new(level, seed)
    self.level = level
    self.theme = level.theme
    self.rng = love.math.newRandomGenerator(seed)

    self.isSolved = false
end

--------------------------------------------------
-- HOOKS PRINCIPAUX
--------------------------------------------------
function PuzzleBase:setup()
    -- appelé UNE FOIS à la génération du level
end

function PuzzleBase:update(dt, player)
    -- logique temps réel
end

function PuzzleBase:draw()
    -- indices visuels optionnels
end

function PuzzleBase:checkSolved()
    return false
end

function PuzzleBase:onSolved()
    self.isSolved = true
end

function PuzzleBase:onActivated()
    -- son, flash, texte, bruit, ennemis alertés, etc
end

return PuzzleBase
