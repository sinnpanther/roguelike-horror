local Item = Class:extend()

function Item:new(x, y, type)
    self.x, self.y = x, y
    self.w, self.h = 16, 16 -- Items are smaller than the player
    self.type = "sedative"
    self.entityType = type
    self.isItem = true -- Tag to identify it during collisions
end

function Item:draw()
    -- Draw a small yellow square for the item
    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    love.graphics.setColor(1, 1, 1)
end

return Item