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
    self.invisibleWalls = {}
    self.enemies = {}
    self.ts = TILE_SIZE
    self.side = nil

    -- RNG propre à cette salle
    self.rng = love.math.newRandomGenerator(baseSeed + level)

    -- --- TAILLE EN CASES SELON LE NIVEAU ---
    -- On reste dans un range raisonnable, puis on pourra faire varier avec le niveau
    local minCols, maxCols = 18, 26  -- largeur en cases
    local minRows, maxRows = 12, 18  -- hauteur en cases

    self.gridWidth  = self.rng:random(minCols, maxCols)
    self.gridHeight = self.rng:random(minRows, maxRows)

    -- Conversion en pixels
    self.width  = self.gridWidth * self.ts
    self.height = self.gridHeight * self.ts

    -- On centre la salle sur l'écran
    self.x = (love.graphics.getWidth()  - self.width) / 2
    self.y = (love.graphics.getHeight() - self.height) / 2
end

function Room:generate(entrySide)
    ----------------------------------------------------------------
    -- 1) PORTES (ENTRÉE / SORTIE)
    ----------------------------------------------------------------
    -- On garde exactement le même système de sides
    if entrySide then
        local ex, ey = self:calculateDoorPos(entrySide)
        self.entryDoor = ClosedDoor(self.world, ex, ey, entrySide)
        self.entryDoor.side = entrySide
    end

    local sides = {"north", "south", "west", "east"}
    local possibleSides = {}
    for _, s in ipairs(sides) do
        if s ~= entrySide then
            table.insert(possibleSides, s)
        end
    end
    local exitSide = possibleSides[self.rng:random(1, #possibleSides)]
    local sx, sy = self:calculateDoorPos(exitSide)
    self.door = LevelDoor(self.world, sx, sy, exitSide)
    self.door.side = exitSide

    local doors = {}

    local function addDoorGridData(door)
        if not door then return end
        local gx = math.floor((door.x - self.x) / self.ts)
        local gy = math.floor((door.y - self.y) / self.ts)
        door.gx = gx
        door.gy = gy
        table.insert(doors, door)
    end

    addDoorGridData(self.entryDoor)
    addDoorGridData(self.door)

    -- Test de recouvrement d'une case de bordure avec une porte
    local function tileHasDoor(gx, gy)
        for i = 1, #doors do
            local d = doors[i]
            if d.gx == gx and d.gy == gy then
                return true
            end
        end
        return false
    end

    ----------------------------------------------------------------
    -- 2) MURS EXTÉRIEURS EN GRILLE (1 case = 1 mur), AVEC TROUS AUX PORTES
    ----------------------------------------------------------------
    for gx = 0, self.gridWidth - 1 do
        for gy = 0, self.gridHeight - 1 do
            local isBorder =
            gx == 0 or gx == self.gridWidth - 1 or
                    gy == 0 or gy == self.gridHeight - 1

            if isBorder and not tileHasDoor(gx, gy) then
                local x = self.x + gx * self.ts
                local y = self.y + gy * self.ts
                WorldUtils.addWall(self.world, self.walls, x, y, self.ts, self.ts)
            end
        end
    end

    ----------------------------------------------------------------
    -- 2bis) MURS INVISIBLES AUTOUR DE LA SALLE (ANNEAU DE SÉCURITÉ)
    ----------------------------------------------------------------
    do
        local outer = self.ts -- épaisseur de la barrière extérieure

        -- Haut extérieur
        WorldUtils.addWall(
                self.world,
                self.invisibleWalls,
                self.x - outer,
                self.y - outer,
                self.width + outer * 2,
                outer
        )

        -- Bas extérieur
        WorldUtils.addWall(
                self.world,
                self.invisibleWalls,
                self.x - outer,
                self.y + self.height,
                self.width + outer * 2,
                outer
        )

        -- Gauche extérieur
        WorldUtils.addWall(
                self.world,
                self.invisibleWalls,
                self.x - outer,
                self.y,
                outer,
                self.height
        )

        -- Droite extérieur
        WorldUtils.addWall(
                self.world,
                self.invisibleWalls,
                self.x + self.width,
                self.y,
                outer,
                self.height
        )
    end

    ----------------------------------------------------------------
    -- 3) PILIERS (on peut garder ton système existant pour l'instant)
    ----------------------------------------------------------------
    local gridSize = 100
    local margin = 120

    local cols = math.floor((self.width - margin * 2) / gridSize)
    local rows = math.floor((self.height - margin * 2) / gridSize)

    local baseChance = 15
    local chance = math.min(baseChance + (self.level - 1) * 2, 35)

    for c = 0, cols do
        for r = 0, rows do
            if self.rng:random(1, 100) <= chance then
                local pW, pH = 40, 40
                local pX = self.x + margin + (c * gridSize)
                local pY = self.y + margin + (r * gridSize)
                WorldUtils.addWall(self.world, self.walls, pX, pY, pW, pH)
            end
        end
    end


    -- --- ENNEMIS SELON LE NIVEAU ---
    local Chaser = require "src.entities.enemies.Chaser"

    local maxPerRoom = 4
    local enemyCount = math.min(1 + math.floor(self.level / 2), maxPerRoom)

    for i = 1, enemyCount do
        -- Spawn en cases internes, puis conversion en pixels
        local eMarginTiles = 2
        local gx = self.rng:random(eMarginTiles, self.gridWidth  - eMarginTiles - 1)
        local gy = self.rng:random(eMarginTiles, self.gridHeight - eMarginTiles - 1)

        local ex = self.x + gx * self.ts
        local ey = self.y + gy * self.ts
        table.insert(self.enemies, Chaser(self.world, ex, ey))
    end
end

function Room:draw()
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

    love.graphics.setColor(0.6, 0.6, 0.7)
    for _, wall in ipairs(self.walls) do
        love.graphics.rectangle("fill", wall.x, wall.y, wall.w, wall.h)
    end

    if self.entryDoor then self.entryDoor:draw() end
    if self.door      then self.door:draw()      end

    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end
end

function Room:calculateDoorPos(side)
    local ts = self.ts

    local gx, gy -- coordonnées en cases sur la bordure

    if side == "north" then
        gx = math.floor(self.gridWidth / 2)
        gy = 0
    elseif side == "south" then
        gx = math.floor(self.gridWidth / 2)
        gy = self.gridHeight - 1
    elseif side == "west" then
        gx = 0
        gy = math.floor(self.gridHeight / 2)
    elseif side == "east" then
        gx = self.gridWidth - 1
        gy = math.floor(self.gridHeight / 2)
    end

    local dx = self.x + gx * ts
    local dy = self.y + gy * ts

    return dx, dy
end

return Room