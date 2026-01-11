local Prop = require "src.map.props.Prop"

local RuinWall = Prop:extend()

function RuinWall:new(world, tx, ty, opts)
    opts = opts or {}

    opts.blocksMovement = true
    opts.blocksVision   = true
    opts.type = "ruin"

    RuinWall.super.new(self, world, tx, ty, opts)
end

function RuinWall:draw()
    -- TEMPORAIRE : debug visuel
    -- plus tard sprite selon theme
    love.graphics.setColor(0.45, 0.35, 0.35)
    love.graphics.rectangle(
            "fill",
            self.pos.x,
            self.pos.y,
            self.w,
            self.h
    )
    StyleUtils.resetColor()
end

return RuinWall
