-- main.lua
-- Premier prototype LOVE2D

function love.load()
    -- Taille de la fenêtre
    love.window.setMode(800, 600)
    love.window.setTitle("Roguelike Horror Prototype")

    -- Joueur
    player = {
        x = 400,
        y = 300,
        radius = 10,
        speed = 120
    }
end

function love.update(dt)
    -- Déplacement du joueur
    if love.keyboard.isDown("w") then
        player.y = player.y - player.speed * dt
    end
    if love.keyboard.isDown("s") then
        player.y = player.y + player.speed * dt
    end
    if love.keyboard.isDown("a") then
        player.x = player.x - player.speed * dt
    end
    if love.keyboard.isDown("d") then
        player.x = player.x + player.speed * dt
    end
end

function love.draw()
    -- Fond noir
    love.graphics.clear(0, 0, 0)

    -- Joueur (un cercle blanc pour l’instant)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", player.x, player.y, player.radius)

    -- Texte debug
    love.graphics.print("Prototype horreur - W A S D pour bouger", 10, 10)
end
