local Prop = require "src.map.props.Prop"
local Pillar = Prop:extend()

function Pillar:new(world, tx, ty, theme)
    Pillar.super.new(self, world, tx, ty, 1, 1, {
        blocksMovement = true,
        blocksVision   = true,
        type  = "pillar",
        theme = theme
    })

    --self.sprite = love.graphics.newImage(
    --        "assets/graphics/props/" .. theme .. "/pillar.png"
    --)
    --self.sprite:setFilter("nearest", "nearest")
end

function Pillar:draw()
    --love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
end

return Pillar
