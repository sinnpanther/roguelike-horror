local PuzzleManager = Class:extend()

function PuzzleManager:new(level, seed)
    self.level = level
    self.theme = level.theme
    self.rng = love.math.newRandomGenerator(seed)

    self.puzzle = nil
end

--------------------------------------------------
-- SETUP
--------------------------------------------------
function PuzzleManager:generate()
    local puzzleList = self.theme:getPuzzles()

    if not puzzleList or #puzzleList == 0 then
        return
    end

    local PuzzleClass = puzzleList[self.rng:random(1, #puzzleList)]

    local puzzleSeed = self.rng:random(1, 2^30)
    self.puzzle = PuzzleClass(
            self.level,
            puzzleSeed
    )

    self.puzzle:setup()
end

--------------------------------------------------
-- RUNTIME
--------------------------------------------------
function PuzzleManager:update(dt, player)
    if not self.puzzle or self.puzzle.isSolved then
        return
    end

    self.puzzle:update(dt, player)

    if self.puzzle:checkSolved(player) then
        self.puzzle:onSolved()
        self:_unlockExit()
    end
end

function PuzzleManager:draw()
    if self.puzzle and not self.puzzle.isSolved then
        self.puzzle:draw()
    end
end

--------------------------------------------------
-- EXIT
--------------------------------------------------
function PuzzleManager:_unlockExit()
    self.level.exitUnlocked = true
end

return PuzzleManager
