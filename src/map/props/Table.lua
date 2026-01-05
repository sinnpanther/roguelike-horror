local Prop = require "src.map.props.Prop"
local Table = Prop:extend()

function Table:new(world, x, y, theme)
    local w = TILE_SIZE * 2
    local h = TILE_SIZE

    Table.super.new(self, world, x, y, w, h, {
        blocksMovement = true,
        blocksVision   = false,
        type  = "table",
        theme = theme
    })

    self.sprite = love.graphics.newImage(
            "assets/graphics/props/" .. theme .. "/table.png"
    )
    --self.sprite:setFilter("nearest", "nearest")
end

function Table:draw()
    love.graphics.draw(self.sprite, self.x, self.y)
end

return Table
