local Door = Class:extend()

function Door:new(world, x, y, side, w, h)
    self.world = world
    self.x = x
    self.y = y
    self.w = w or 40
    self.h = h or 40
    self.side = side -- "north", "south", "east", or "west"
    self.type = "door"

    -- Enregistrement dans Bump
    self.world:add(self, self.x, self.y, self.w, self.h)
end

-- Fonction à redéfinir dans les classes filles
function Door:onInteract(player)
    error("La méthode onInteract doit être implémentée par la classe spécialisée")
end

function Door:draw()
    -- Debug visuel par défaut
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
end

return Door