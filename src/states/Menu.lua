local Menu = {}

function Menu:enter()
    self.options = {"Nouvelle partie", "Options", "Quitter"}
    self.selection = 1
    self.font = love.graphics.newFont(30)
    self.titleFont = love.graphics.newFont(60)
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

    -- Titre
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("Latente Fear", 0, 150, love.graphics.getWidth(), "center")

    -- Options
    love.graphics.setFont(self.font)
    for i, option in ipairs(self.options) do
        local color = {0.5, 0.5, 0.5} -- Gris par défaut

        if i == self.selection then
            color = {1, 1, 0} -- Jaune si sélectionné
        end

        love.graphics.setColor(color)
        love.graphics.printf(option, 0, 300 + (i * 50), love.graphics.getWidth(), "center")
    end
    love.graphics.setColor(1, 1, 1) -- Reset couleur
end

function Menu:leave()
    -- Reset de la police
    local normalFont = love.graphics.newFont(14)
    love.graphics.setFont(normalFont)

    -- Reset des couleurs de fond
    love.graphics.setColor(1, 1, 1)
end

return Menu