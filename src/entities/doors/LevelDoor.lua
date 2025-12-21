local Door = require "src.entities.doors.Door"
local LevelDoor = Door:extend()

function LevelDoor:new(world, x, y, side)
    -- On appelle le constructeur parent (Door)
    LevelDoor.super.new(self, world, x, y, side)
end

function LevelDoor:onInteract(player)
    -- Logique spécifique au changement de niveau
    player.hasReachedExit = true
    player.lastExitSide = self.side
end

function LevelDoor:draw()
    -- Style visuel de la porte de niveau
    love.graphics.setColor(0, 1, 0.6) -- Vert émeraude
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    -- Bordure
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
end

return LevelDoor