local Prop = require "src.map.props.Prop"
local Pillar = Prop:extend()

function Pillar:new(world, tx, ty, opts)
    opts = opts or {}
    opts.blocksMovement = true
    opts.blocksVision   = true
    opts.type  = "pillar"
    opts.spriteH = TILE_SIZE * 2

    Pillar.super.new(self, world, tx, ty, opts)

    --self.sprite = love.graphics.newImage(
    --        "assets/graphics/props/" .. theme .. "/pillar.png"
    --)
    --self.sprite:setFilter("nearest", "nearest")
end

function Pillar:draw()
    local x = self.pos.x
    local y = self.pos.y

    -- Ancrage au sol :
    -- le bas du rectangle visuel est aligné avec le bas de la collision
    local drawY = y + self.h - self.spriteH

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle(
            "fill",
            x,
            drawY,
            self.w,
            self.spriteH
    )

    StyleUtils.resetColor()
end

return Pillar
