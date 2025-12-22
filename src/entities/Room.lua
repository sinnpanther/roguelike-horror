-- Dependancies
local LevelDoor = require "src.entities.doors.LevelDoor"
local ClosedDoor = require "src.entities.doors.ClosedDoor"
-- Utils
local WorldUtils = require "src.utils.world_utils"

local Room = Class:extend()

function Room:new(world, baseSeed, level)
    self.world = world
    self.level = level
    self.walls = {}
    self.enemies = {}

    -- On crée une seed unique pour cette salle précise
    -- Ainsi, la salle 1 est toujours la même, la 2 aussi, etc.
    self.rng = love.math.newRandomGenerator(baseSeed + level)

    -- --- TAILLE SELON LE NIVEAU ---
    local minW, maxW = 600, 900
    local minH, maxH = 400, 700

    local sizeBoost = math.min((level - 1) * 20, 150)
    self.width  = self.rng:random(minW, maxW + sizeBoost)
    self.height = self.rng:random(minH, maxH + sizeBoost)

    -- On centre la salle sur l'écran
    self.x = (love.graphics.getWidth() - self.width) / 2
    self.y = (love.graphics.getHeight() - self.height) / 2
end

function Room:generate(entrySide)
    local t = 20 -- épaisseur des murs (thickness)

    -- Murs extérieurs (Bords de la salle)
    WorldUtils.addWall(self.world, self.walls, self.x, self.y, self.width, t) -- Haut
    WorldUtils.addWall(self.world, self.walls, self.x, self.y + self.height - t, self.width, t) -- Bas
    WorldUtils.addWall(self.world, self.walls, self.x, self.y, t, self.height) -- Gauche
    WorldUtils.addWall(self.world, self.walls, self.x + self.width - t, self.y, t, self.height) -- Droite

    -- Configuration de la grille pour les piliers
    local gridSize = 100 -- Distance entre deux emplacements de piliers
    local margin = 120   -- Distance minimale avec les murs extérieurs

    -- On calcule combien de piliers on peut caser en largeur et hauteur
    local cols = math.floor((self.width - margin * 2) / gridSize)
    local rows = math.floor((self.height - margin * 2) / gridSize)

    -- Chance de pilier par case (augmente un peu avec le niveau)
    local baseChance = 15
    local chance = math.min(baseChance + (self.level - 1) * 2, 35)

    -- On parcourt la grille
    for c = 0, cols do
        for r = 0, rows do
            if self.rng:random(1, 100) <= chance then
                local pW, pH = 40, 40

                -- Position alignée sur la grille
                local pX = self.x + margin + (c * gridSize)
                local pY = self.y + margin + (r * gridSize)

                WorldUtils.addWall(self.world, self.walls, pX, pY, pW, pH)
            end
        end
    end

    -- Door
    -- 1. CALCUL DE LA PORTE D'ENTRÉE (FERMÉE)
    if entrySide then
        local ex, ey = self:calculateDoorPos(entrySide)
        self.entryDoor = ClosedDoor(self.world, ex, ey, entrySide)
    end

    -- 2. CALCUL DE LA PORTE DE SORTIE (OUVERTE)
    local sides = {"north", "south", "west", "east"}

    -- On crée une liste de côtés possibles en enlevant celui d'entrée
    local possibleSides = {}
    for _, s in ipairs(sides) do
        if s ~= entrySide then
            table.insert(possibleSides, s)
        end
    end

    -- On choisit parmi les côtés restants
    local exitSide = possibleSides[self.rng:random(1, #possibleSides)]
    local sx, sy = self:calculateDoorPos(exitSide)
    self.door = LevelDoor(self.world, sx, sy, exitSide)

    -- --- NOMBRE D'ENNEMIS SELON LE NIVEAU ---
    local Chaser = require "src.entities.enemies.Chaser"

    local maxPerRoom = 4
    local enemyCount = math.min(1 + math.floor(self.level / 2), maxPerRoom)

    for i = 1, enemyCount do
        -- On les place un peu au hasard dans la salle, avec une marge pour éviter les murs
        local eMargin = 80
        local ex = self.rng:random(self.x + eMargin, self.x + self.width  - eMargin - 32)
        local ey = self.rng:random(self.y + eMargin, self.y + self.height - eMargin - 32)
        table.insert(self.enemies, Chaser(self.world, ex, ey))
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

    -- Doors
    if self.entryDoor then self.entryDoor:draw() end
    if self.door then self.door:draw() end

    -- Enemies
    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end
end

function Room:calculateDoorPos(side)
    local dx, dy
    if side == "north" then
        dx, dy = self.x + (self.width / 2) - 20, self.y
    elseif side == "south" then
        dx, dy = self.x + (self.width / 2) - 20, self.y + self.height - 40
    elseif side == "west" then
        dx, dy = self.x, self.y + (self.height / 2) - 20
    elseif side == "east" then
        dx, dy = self.x + self.width - 40, self.y + (self.height / 2) - 20
    end
    return dx, dy
end

return Room