local Victory = {}

function Victory:enter(from, stats)
    -- "from" serait l'état précédent (Play), "stats" peut contenir des infos sur la run
    self.stats = stats or {}
end

function Victory:update(dt)
    -- Pas forcément besoin de logique pour l'instant
end

function Victory:draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    love.graphics.clear(0, 0, 0)
    StyleUtils.resetColor()

    local title = "TU AS SURVECU AUX PROFONDEURS"
    local info  = "Tu as atteint l'etage 10."
    local hint1 = "Appuie sur ENTREE pour rejouer"
    local hint2 = "Appuie sur ECHAP pour quitter"

    love.graphics.printf(title, 0, h * 0.3, w, "center")
    love.graphics.printf(info,  0, h * 0.4, w, "center")
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.printf(hint1, 0, h * 0.55, w, "center")
    love.graphics.printf(hint2, 0, h * 0.6,  w, "center")
end

function Victory:keypressed(key)
    if key == "return" or key == "kpenter" then
        -- Relancer une partie
        local Play = require "src.states.Play"
        GameState.switch(Play)
    elseif key == "escape" then
        love.event.quit()
    end
end

return Victory