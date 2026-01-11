local Prop = require "src.map.props.Prop"
local Pillar = Prop:extend()

function Pillar:new(world, tx, ty, opts)
    opts = opts or {}
    opts.blocksMovement = true
    opts.blocksVision   = true
    opts.type  = "pillar"

    Pillar.super.new(self, world, tx, ty, 1, 1, opts)

    --self.sprite = love.graphics.newImage(
    --        "assets/graphics/props/" .. theme .. "/pillar.png"
    --)
    --self.sprite:setFilter("nearest", "nearest")
end

function Pillar:draw()
    --love.graphics.rectangle("line", self.pos.x, self.pos.y, self.w, self.h)
end

return Pillar
