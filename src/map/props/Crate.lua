local Prop = require "src.map.props.Prop"
local Crate = Prop:extend()

function Crate:new(world, x, y, theme)
    local size = TILE_SIZE

    Crate.super.new(self, world, x, y, size, size, {
        blocksMovement = true,
        blocksVision   = false,
        type  = "crate",
        theme = theme
    })

    self.sprite = love.graphics.newImage(
            "assets/graphics/props/" .. theme .. "/crate.png"
    )
    --self.sprite:setFilter("nearest", "nearest")
end

function Crate:draw()
    love.graphics.draw(self.sprite, self.x, self.y)
end

return Crate
