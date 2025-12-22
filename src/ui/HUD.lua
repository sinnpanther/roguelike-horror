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


    -- Instruction pour tester
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print("Appuyez sur 'N' pour changer de salle", 20, love.graphics.getHeight() - 30)
end

return HUD