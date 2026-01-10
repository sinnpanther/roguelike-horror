local Inventory = {}

function Inventory:enter(parent)
    self.parent = parent
    self.parent.player.controlsEnabled = false

    self.titleFont = love.graphics.newFont(48)
end

-- ❗ PAS de update du monde ici
function Inventory:update(dt)
    self.parent:update(dt)
end

function Inventory:draw()
    -- 1️⃣ DESSIN DE L'ÉTAT EN DESSOUS
    self.parent:draw()

    -- 2️⃣ OVERLAY
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0,
            love.graphics.getWidth(),
            love.graphics.getHeight()
    )

    -- 3️⃣ UI inventaire
    love.graphics.setFont(self.titleFont)
    StyleUtils.resetColor()
    love.graphics.printf("Inventaire", 0, 80, love.graphics.getWidth(), "center")
    self:reset()
end

function Inventory:keypressed(key)
    if key == "escape" or key == "i" then
        GameState.pop()
    end
end

function Inventory:leave()
    self:reset()
    self.parent.player.controlsEnabled = true
end

function Inventory:reset()
    -- Reset de la police
    StyleUtils.resetFont()

    -- Reset des couleurs de fond
    StyleUtils.resetColor()
end

return Inventory
