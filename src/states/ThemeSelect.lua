local ThemeSelect = {}
local ThemeManager = require "src.map.themes.ThemeManager"

function ThemeSelect:enter(_, data)
    self.onSelect = data.onSelect
    self.rng = data.rng

    self.themes = ThemeManager.pickRandom(self.rng, 3)
    self.selection = 1

    self.titleFont = love.graphics.newFont(48)
    self.font = love.graphics.newFont(22)
end

function ThemeSelect:update(dt)
    -- rien pour l’instant
end

function ThemeSelect:keypressed(key)
    if key == "left" then
        self.selection = math.max(1, self.selection - 1)
    elseif key == "right" then
        self.selection = math.min(#self.themes, self.selection + 1)
    elseif key == "return" or key == "kpenter" or key == "space" then
        self.onSelect(self.themes[self.selection])
    end
end

function ThemeSelect:draw()
    love.graphics.clear(0.05, 0.05, 0.05)

    love.graphics.setFont(self.titleFont)
    love.graphics.printf("Choisi ta voie", 0, 80, love.graphics.getWidth(), "center")

    love.graphics.setFont(self.font)

    local w = love.graphics.getWidth()
    local y = 260
    local spacing = 300

    for i, ThemeClass in ipairs(self.themes) do
        local x = w * 0.5 + (i - 2) * spacing
        local color = i == self.selection and {1, 1, 0} or {0.7, 0.7, 0.7}

        love.graphics.setColor(color)
        love.graphics.printf(
                ThemeClass.NAME or "Thème inconnu",
                x - 120, y, 240, "center"
        )
    end

    StyleUtils.resetColor()
end

function ThemeSelect:leave()
    -- Reset de la police
    StyleUtils.resetFont()

    -- Reset des couleurs de fond
    StyleUtils.resetColor()
end

return ThemeSelect
