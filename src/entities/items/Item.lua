local Vector = require "libs.hump.vector"

local Item = Class:extend()

function Item:new(x, y, type)
    self.pos = Vector(x, y)
    self.w, self.h = 16, 16 -- Items are smaller than the player
    self.type = "sedative"
    self.entityType = type
    self.isItem = true -- Tag to identify it during collisions
end

function Item:draw()
    -- Draw a small yellow square for the item
    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle("fill", self.pos.x, self.pos.y, self.w, self.h)
    StyleUtils.resetColor()
end

return Item