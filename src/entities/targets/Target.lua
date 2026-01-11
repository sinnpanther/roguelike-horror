-- Target lambda (utile pour plusieurs choses, à hériter pour créer des targets spécifiques)
local Vector = require "libs.hump.vector"

local Target = Class:extend()

function Target:new(x, y, w, h, opts)
    self.pos = Vector(x, y)
    self.w = w
    self.h = h

    self:_initOptions(opts or {})
end

function Target:getCenter()
    return self.pos.x + self.w / 2, self.pos.y + self.h / 2
end

function Target:_initOptions(opts)
    if opts then
        for k, v in pairs(opts) do
            self[k] = v
        end
    end
end

return Target
