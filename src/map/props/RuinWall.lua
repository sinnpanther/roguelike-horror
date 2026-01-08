local Prop = require "src.map.props.Prop"

local RuinWall = Prop:extend()

function RuinWall:new(world, tileX, tileY, opts)
    opts = opts or {}

    opts.blocksMovement = true
    opts.blocksVision   = true
    opts.type = "ruin"

    RuinWall.super.new(
            self,
            world,
            tileX,
            tileY,
            1, -- largeur en tiles
            1, -- hauteur en tiles
            opts
    )
end

function RuinWall:draw()
    -- TEMPORAIRE : debug visuel
    -- plus tard sprite selon theme
    love.graphics.setColor(0.45, 0.35, 0.35)
    love.graphics.rectangle(
            "fill",
            self.x,
            self.y,
            self.w,
            self.h
    )
    love.graphics.setColor(1, 1, 1)
end

return RuinWall
