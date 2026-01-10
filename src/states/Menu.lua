local Suit = require "libs.suit"

local Menu = {}

function Menu:enter()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    self.layoutX = screenW / 2 - 100
    self.layoutY = screenH / 2 - 40

    -- Liste logique du menu
    self.items = {
        {
            label = "Nouvelle partie",
            action = function()
                GameState.switch(States.Play)
            end
        },
        {
            label = "Options",
            action = function()
                print("Options...")
            end
        },
        {
            label = "Quitter",
            action = function()
                love.event.quit()
            end
        }
    }

    self.selected = 1

    -- Police UI chargée une seule fois
    self.uiFont = StyleUtils.newFont()
    self.uiFont:setFilter("linear", "linear")

    self.titleFont = love.graphics.newFont("assets/fonts/HorrorFont-Regular.ttf", 52)
    self.titleFont:setFilter("linear", "linear")
end

--------------------------------------------------
-- CLAVIER
--------------------------------------------------
function Menu:keypressed(key)
    if key == "up" or key == "z" then
        self.selected = self.selected - 1
        if self.selected < 1 then
            self.selected = #self.items
        end
    elseif key == "down" or key == "s" then
        self.selected = self.selected + 1
        if self.selected > #self.items then
            self.selected = 1
        end
    elseif key == "return" or key == "kpenter" or key == "space" then
        local item = self.items[self.selected]
        if item and item.action then
            item.action()
        end
    end
end

--------------------------------------------------
-- UPDATE (SUIT)
--------------------------------------------------
function Menu:update(dt)
    Suit.layout:reset(self.layoutX, self.layoutY)
    Suit.layout:padding(20)

    for i, item in ipairs(self.items) do
        local isSelected = (i == self.selected)
        -- Style différent si sélection clavier
        local style = {
            id = item.label,
            font = self.uiFont,
            color = {
                normal = {
                    fg = isSelected and {1, 1, 0, 1} or {0.7, 0.7, 0.7, 1},
                    bg = {0.2, 0.2, 0.2, 0.6}
                },
                hovered = {
                    fg = {1, 1, 0, 1},
                    bg = {0.3, 0.3, 0.3, 0.8}
                },
                active = {
                    fg = {0, 0, 0, 0.6},
                    bg = {1, 1, 0, 1}
                }
            }
        }

        if Suit.Button(item.label, style, Suit.layout:row(200, 36)).hit then
            self.selected = i
            item.action()
        end
    end
end

--------------------------------------------------
-- DRAW
--------------------------------------------------
function Menu:draw()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

    -- Titre
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(
            "Latente Fear",
            0,
            self.layoutY - 90,
            love.graphics.getWidth(),
            "center"
    )

    -- UI
    Suit.draw()

    -- Reset sécurité
    StyleUtils.resetColor()
    StyleUtils.resetFont()
end

return Menu
