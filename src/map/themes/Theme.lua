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
    -- implémenté dans les enfants
end

return Theme
