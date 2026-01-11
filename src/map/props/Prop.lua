local Vector = require "libs.hump.vector"

local Prop = Class:extend()

function Prop:new(world, tx, ty, opts, tw, th)
    opts = opts or {}

    -- Coordonnées en tiles
    self.tx = tx
    self.ty = ty
    self.tw = tw or 1
    self.th = th or 1

    -- Conversion monde (pixels)
    local px = (self.tx - 1) * TILE_SIZE
    local py = (self.ty - 1) * TILE_SIZE
    self.pos = Vector(px, py)
    self.w = self.tw * TILE_SIZE
    self.h = self.th * TILE_SIZE

    self.spriteW = self.w
    self.spriteH = opts.spriteH or self.h * 2

    self.world = world

    self.blocksMovement = opts.blocksMovement or false
    self.blocksVision   = opts.blocksVision   or false

    self.type  = opts.type  or "generic"
    self.theme = opts.theme.ID or "generic"

    if self.blocksMovement then
        self.collider = world:add(self, self.pos.x, self.pos.y, self.w, self.h)
    end
end

function Prop:draw()
    -- implémenté dans les enfants
end

return Prop
