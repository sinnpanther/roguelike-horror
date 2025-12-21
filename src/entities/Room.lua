local Room = Class:extend()
local WorldUtils = require "src.utils.world_utils"

function Room:new(world, baseSeed, level)
    self.world = world
    self.level = level
    self.walls = {}

    -- On crée une seed unique pour cette salle précise
    -- Ainsi, la salle 1 est toujours la même, la 2 aussi, etc.
    self.rng = love.math.newRandomGenerator(baseSeed + level)

    -- 1. On définit une taille de salle aléatoire
    self.width = self.rng:random(600, 900)
    self.height = self.rng:random(400, 700)

    -- On centre la salle sur l'écran (optionnel, selon ton choix de caméra)
    self.x = (love.graphics.getWidth() - self.width) / 2
    self.y = (love.graphics.getHeight() - self.height) / 2

    self:generate()
end

function Room:generate()
    local t = 20 -- épaisseur des murs (thickness)

    -- Murs extérieurs (Bords de la salle)
    WorldUtils.addWall(self.world, self.walls, self.x, self.y, self.width, t) -- Haut
    WorldUtils.addWall(self.world, self.walls, self.x, self.y + self.height - t, self.width, t) -- Bas
    WorldUtils.addWall(self.world, self.walls, self.x, self.y, t, self.height) -- Gauche
    WorldUtils.addWall(self.world, self.walls, self.x + self.width - t, self.y, t, self.height) -- Droite

    -- 2. Configuration de la grille pour les piliers
    local gridSize = 100 -- Distance entre deux emplacements de piliers
    local margin = 120   -- Distance minimale avec les murs extérieurs

    -- On calcule combien de piliers on peut caser en largeur et hauteur
    local cols = math.floor((self.width - margin * 2) / gridSize)
    local rows = math.floor((self.height - margin * 2) / gridSize)

    -- 3. On parcourt la grille
    for c = 0, cols do
        for r = 0, rows do
            -- On ne met pas un pilier partout !
            -- On utilise le RNG pour décider (ex: 15% de chance par case)
            if self.rng:random(1, 100) <= 15 then
                local pW, pH = 40, 40

                -- Position alignée sur la grille
                local pX = self.x + margin + (c * gridSize)
                local pY = self.y + margin + (r * gridSize)

                WorldUtils.addWall(self.world, self.walls, pX, pY, pW, pH)
            end
        end
    end
end

function Room:draw()
    -- Dessin du sol
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    -- Dessin des murs et obstacles
    love.graphics.setColor(0.6, 0.6, 0.7)
    for _, wall in ipairs(self.walls) do
        love.graphics.rectangle("fill", wall.x, wall.y, wall.w, wall.h)
    end
end

return Room