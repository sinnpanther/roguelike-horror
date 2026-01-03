local Prop = Class:extend()

function Prop:new(world, tileX, tileY, tileW, tileH, opts)
    opts = opts or {}

    -- Coordonnées en tiles
    self.tx = tileX
    self.ty = tileY
    self.tw = tileW or 1
    self.th = tileH or 1

    -- Conversion monde (pixels)
    self.x = (self.tx - 1) * TILE_SIZE
    self.y = (self.ty - 1) * TILE_SIZE
    self.w = self.tw * TILE_SIZE
    self.h = self.th * TILE_SIZE

    self.world = world

    self.blocksMovement = opts.blocksMovement or false
    self.blocksVision   = opts.blocksVision   or false

    self.type  = opts.type  or "generic"
    self.theme = opts.theme or "generic"

    if self.blocksMovement then
        self.collider = world:add(self, self.x, self.y, self.w, self.h)
    end
end

function Prop:draw()
    -- implémenté dans les enfants
end

return Prop
