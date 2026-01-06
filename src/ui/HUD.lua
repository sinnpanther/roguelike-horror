local HUD = Class:extend()

function HUD:new(player)
    self.player = player
end

function HUD:draw(level, displaySeed)
    -- On affiche les infos en haut à gauche
    love.graphics.setColor(1, 1, 1, 1) -- Blanc

    -- Niveau actuel
    love.graphics.print("ETAGE : " .. level, 20, 20)

    -- Seed (en petit, c'est une info technique)
    love.graphics.print("SEED : " .. displaySeed, 20, 40)

    -- BARRE DE VIE PLAYER
    local barW = 140
    local barH = 12
    local x = 20
    local y = love.graphics.getHeight() - 30

    -- Fond
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.rectangle("line", x, y, barW, barH)

    -- Vie
    local ratio = self.player.hp / self.player.maxHp
    love.graphics.setColor(0.8, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", x, y, barW * ratio, barH)

    love.graphics.setColor(1, 1, 1)

    if DEBUG_MODE then
        self:debug()
    end
end

function HUD:debug()
    love.graphics.printf("DEBUG MODE - FPS: " .. love.timer.getFPS(), 10, 10, love.graphics.getWidth() - 20, "right")
end

return HUD