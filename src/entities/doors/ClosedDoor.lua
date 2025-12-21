local Door = require "src.entities.doors.Door"
local ClosedDoor = Door:extend()

function ClosedDoor:new(world, x, y, side)
    ClosedDoor.super.new(self, world, x, y, side)

    -- IMPORTANT : On la retire du monde Bump immédiatement
    -- Comme ça, elle reste visuelle mais n'arrête pas le joueur et n'est pas interactive
    if self.world:hasItem(self) then
        self.world:remove(self)
    end
end

function ClosedDoor:onInteract(player)
    -- On ne fait rien du tout
end

function ClosedDoor:draw()
    love.graphics.setColor(0.3, 0.3, 0.3) -- Gris foncé / éteint
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    love.graphics.setColor(1, 0, 0) -- Un petit liseré rouge pour "fermé"
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
    love.graphics.setColor(1, 1, 1)
end

return ClosedDoor