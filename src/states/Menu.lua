local Menu = {}

function Menu:enter()
    self.options = {"Nouvelle partie", "Options", "Quitter"}
    self.selection = 1
    self.font = love.graphics.newFont(30)
    self.titleFont = love.graphics.newFont(60)

    --self.mainTheme = love.audio.newSource("assets/audio/musics/main_theme.mp3", 'static')
    --love.audio.play(self.mainTheme)
end

function Menu:keypressed(key)
    if key == "z" or key == "up" then
        self.selection = self.selection - 1
        if self.selection < 1 then self.selection = #self.options end
    elseif key == "s" or key == "down" then
        self.selection = self.selection + 1
        if self.selection > #self.options then self.selection = 1 end
    elseif key == "return" or key == "space" then
        self:confirmSelection()
    end
end

function Menu:confirmSelection()
    if self.selection == 1 then
        GameState.switch(States.Play) -- On lance le jeu
    elseif self.selection == 2 then
        print("Ouverture des options...")
    elseif self.selection == 3 then
        love.event.quit()
    end
end

function Menu:draw()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- === PARAMÈTRES MENU ===
    local titleYSpacing = 40        -- espace entre titre et options
    local optionSpacing = 50        -- espace entre chaque option
    local optionCount = #self.options

    -- === POLICES ===
    love.graphics.setFont(self.titleFont)
    local titleHeight = self.titleFont:getHeight()

    love.graphics.setFont(self.font)
    local optionHeight = self.font:getHeight()

    -- === HAUTEUR TOTALE DU MENU ===
    local menuHeight =
    titleHeight +
            titleYSpacing +
            (optionCount * optionHeight) +
            ((optionCount - 1) * (optionSpacing - optionHeight))

    -- === POINT DE DÉPART VERTICAL (centrage) ===
    local startY = (screenH - menuHeight) / 2

    -- === DESSIN DU TITRE ===
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
            "Latente Fear",
            0,
            startY,
            screenW,
            "center"
    )

    -- === DESSIN DES OPTIONS ===
    love.graphics.setFont(self.font)
    for i, option in ipairs(self.options) do
        if i == self.selection then
            love.graphics.setColor(1, 1, 0)
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
        end

        local y = startY + titleHeight + titleYSpacing + (i - 1) * optionSpacing

        love.graphics.printf(
                option,
                0,
                y,
                screenW,
                "center"
        )
    end

    love.graphics.setColor(1, 1, 1)
end

function Menu:leave()
    -- Reset de la police
    local normalFont = love.graphics.newFont(14)
    love.graphics.setFont(normalFont)

    -- Reset des couleurs de fond
    love.graphics.setColor(1, 1, 1)

    --love.audio.stop(self.mainTheme)
end

return Menu