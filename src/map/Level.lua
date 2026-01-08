-- Dependancies
local LayoutFactory = require "src.map.layouts.LayoutFactory"
--local Room = require "src.map.Room"
--local Corridor = require "src.map.Corridor"
local SpatialHash = require "src.map.SpatialHash"

-- Utils
local WorldUtils = require "src.utils.world_utils"
local MapUtils = require "src.utils.map_utils"

local Level = Class:extend()

function Level:new(world, seed, levelIndex)
    self.world = world
    self.rng = love.math.newRandomGenerator(seed)
    self.levelIndex = levelIndex
    self.spatialHash = SpatialHash(TILE_SIZE * 2)

    self.ts = TILE_SIZE
    self.mapW, self.mapH = 200, 160 -- en tiles (à ajuster)

    -- Map
    -- 0 = Vide
    -- 1 = Sol
    -- 2 = Mur
    -- 3 = Pillar
    -- 4 = Verre
    self.map = {}
    self.rooms = {}
    self.walls = {}

    self.theme = nil

    self.tileset = love.graphics.newImage("assets/graphics/tiles/tileset.png")

    local tw, th = self.tileset:getWidth(), self.tileset:getHeight()

    -- Quads pré-calculés
    -- Sol (tes coords actuelles)
    self.floorQuad = love.graphics.newQuad(32, 32, self.ts, self.ts, tw, th)
    -- Mur (tes coords actuelles)
    self.wallQuad  = love.graphics.newQuad(0, 256, self.ts, self.ts, tw, th)

    -- SpriteBatches (remplis après génération)
    self.floorBatch = nil
    self.wallBatch  = nil
end

function Level:buildTileBatches()
    local maxTiles = self.mapW * self.mapH

    self.floorBatch = love.graphics.newSpriteBatch(self.tileset, maxTiles, "static")
    self.wallBatch  = love.graphics.newSpriteBatch(self.tileset, maxTiles, "static")

    self.floorBatch:clear()
    self.wallBatch:clear()

    -- On garde une liste des tiles verre (en pixels) pour dessiner les contours
    self.glassTiles = {}

    for y = 1, self.mapH do
        for x = 1, self.mapW do
            local tile = self.map[y][x]
            local px = (x - 1) * self.ts
            local py = (y - 1) * self.ts

            if tile == TILE_FLOOR or tile == TILE_CORRIDOR then
                self.floorBatch:add(self.floorQuad, px, py)

            elseif tile == TILE_WALL then
                self.wallBatch:add(self.wallQuad, px, py)

            elseif tile == TILE_GLASS then
                -- verre = sol normal (visuel identique) + contour
                self.floorBatch:add(self.floorQuad, px, py)

                -- on stocke la position pour le contour
                self.glassTiles[#self.glassTiles + 1] = { px = px, py = py }
            end
        end
    end

    self.floorBatch:flush()
    self.wallBatch:flush()
end

function Level:drawGlassDetails()
    if not self.glassTiles or #self.glassTiles == 0 then
        return
    end

    local ts = self.ts

    -- Lignes plus jolies
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("bevel") -- chez toi "round" n'existe pas
    love.graphics.setLineWidth(2)

    for i = 1, #self.glassTiles do
        local t = self.glassTiles[i]
        local x = t.px
        local y = t.py

        -- Alignement pixel
        local ox = x + 0.5
        local oy = y + 0.5

        --------------------------------------------------
        -- 1) CONTOUR TURQUOISE
        --------------------------------------------------
        love.graphics.setColor(0.15, 0.95, 0.9, 0.9)
        love.graphics.rectangle("line", ox, oy, ts - 1, ts - 1)

        --------------------------------------------------
        -- 2) REFLETS (2 diagonales courtes)
        -- On dessine des traits clairs à l'intérieur de la tile
        --------------------------------------------------
        love.graphics.setLineWidth(1.5)
        love.graphics.setColor(0.85, 1.0, 1.0, 0.45)

        -- premier reflet (haut-gauche vers milieu)
        love.graphics.line(
                ox + 3,  oy + 5,
                ox + 10, oy + 2
        )

        -- second reflet (milieu vers bas-droite)
        love.graphics.line(
                ox + 6,  oy + ts - 6,
                ox + ts - 3, oy + ts - 9
        )

        --------------------------------------------------
        -- 3) SPARKLE (optionnel, discret)
        -- Pas besoin d'un vrai RNG : on fait une pseudo variation stable
        --------------------------------------------------
        love.graphics.setLineWidth(2)
        local s = (math.sin((x * 0.013) + (y * 0.017) + (love.timer.getTime() * 2.0)) + 1) * 0.5
        if s > 0.92 then
            love.graphics.setColor(0.95, 1.0, 1.0, 0.35)
            local cx = ox + ts * 0.65
            local cy = oy + ts * 0.35
            love.graphics.line(cx - 2, cy, cx + 2, cy)
            love.graphics.line(cx, cy - 2, cx, cy + 2)
        end

        -- reset line width for next tile
        love.graphics.setLineWidth(2)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function Level:generate()
    self:_initTiles(TILE_EMPTY)

    local profile = self.theme:getProfile()
    local layout = LayoutFactory.create(profile, self)

    layout:build()

    --------------------------------------------------
    -- CONTENT PER ROOM
    --------------------------------------------------
    for _, room in ipairs(self.rooms) do
        if profile.hasInternalWalls then
            room:buildInternalWalls(profile)
        end

        if profile.hasPillars then
            room:generatePillars(profile)
        end

        if profile.hasProps then
            room:spawnProps(profile)
        end

        if profile.hasEnemies then
            room:spawnEnemies(profile)
        end

        self.theme:decorate(room)
    end

    --------------------------------------------------
    -- WALLS
    --------------------------------------------------
    if profile.hasOuterWalls then
        self:_buildAutoWalls()
        self:_buildWallColliders()
    end

    --------------------------------------------------
    -- TILE BATCHES
    --------------------------------------------------
    self:buildTileBatches()

    self.mainRoom = self.rooms[1]
end

function Level:draw()
    -- Sol
    if self.floorBatch then
        love.graphics.draw(self.floorBatch, 0, 0)
    end

    -- Contours verre (par-dessus le sol, avant les murs)
    self:drawGlassDetails()

    -- Murs
    if self.wallBatch then
        love.graphics.draw(self.wallBatch, 0, 0)
    end

    for _, room in ipairs(self.rooms) do
        for _, enemy in ipairs(room.enemies) do
            enemy:draw()
        end
    end

    for _, room in ipairs(self.rooms) do
        for _, prop in ipairs(room.props) do
            prop:draw()
        end
    end
end

function Level:drawWallsOnly()
    if self.wallBatch then
        love.graphics.draw(self.wallBatch, 0, 0)
    end
end

function Level:_initTiles(fillValue)
    for y = 1, self.mapH do
        self.map[y] = {}
        for x = 1, self.mapW do
            self.map[y][x] = fillValue
        end
    end
end

function Level:_buildAutoWalls()
    for y = 1, self.mapH do
        for x = 1, self.mapW do
            if self.map[y][x] == 0 and self:_hasAdjacentFloor(x, y) then
                self.map[y][x] = TILE_WALL
            end
        end
    end
end

function Level:_buildWallColliders()
    for y = 1, self.mapH do
        for x = 1, self.mapW do
            if self.map[y][x] == TILE_WALL then
                local px = (x - 1) * self.ts
                local py = (y - 1) * self.ts

                WorldUtils.addWall(self.world, self.walls, px, py, self.ts, self.ts)
            end
        end
    end
end

function Level:_hasAdjacentFloor(x, y)
    local function isFloor(tx, ty)
        if tx < 1 or tx > self.mapW or ty < 1 or ty > self.mapH then
            return false
        end

        return MapUtils:isWalkableTile(self.map, tx, ty)
    end

    -- Cardinal
    if isFloor(x+1, y) or isFloor(x-1, y)
            or isFloor(x, y+1) or isFloor(x, y-1) then
        return true
    end

    -- Diagonales (coins)
    if isFloor(x+1, y+1) or isFloor(x-1, y-1)
            or isFloor(x+1, y-1) or isFloor(x-1, y+1) then
        return true
    end

    return false
end

--function Level:buildQuads()
--    self.quads = {}
--
--    for y = 1, self.mapH do
--        self.quads[y] = {}
--        for x = 1, self.mapW do
--            if self.map[y][x] == TILE_WALL then
--                self.quads[y][x] = AutoTile.getQuad(
--                        self.map,
--                        x,
--                        y,
--                        self.tileset
--                )
--            end
--        end
--    end
--end

--------------------------------------------------
-- Tile lookup à partir de coordonnées monde (pixels)
--------------------------------------------------
function Level:getTileAtPixel(px, py)
    local tx = math.floor(px / self.ts) + 1
    local ty = math.floor(py / self.ts) + 1

    if ty < 1 or ty > self.mapH or tx < 1 or tx > self.mapW then
        return nil, tx, ty
    end

    return self.map[ty][tx], tx, ty
end

function Level:getTileAtWorld(x, y)
    local tx = math.floor(x / TILE_SIZE) + 1
    local ty = math.floor(y / TILE_SIZE) + 1

    if not self.map[ty] or not self.map[ty][tx] then
        return nil
    end

    return self.map[ty][tx]
end

--------------------------------------------------
-- Bruit : notifie les ennemis proches (spatial hash)
-- strength : 0..1 (optionnel)
--------------------------------------------------
function Level:emitNoise(x, y, radius, strength)
    radius = radius or 520
    strength = strength or 1.0

    local nearbyEnemies = self.spatialHash:queryRect(
            x - radius,
            y - radius,
            radius * 2,
            radius * 2,
            function(e)
                return e.entityType == "enemy"
            end
    )

    for _, enemy in ipairs(nearbyEnemies) do
        if enemy.onNoiseHeard then
            enemy:onNoiseHeard(x, y, strength)
        else
            -- fallback si tu n'as pas encore le hook
            enemy.lastHeardNoisePos = { x = x, y = y }
            enemy.timeSinceHeard = 0
        end
    end
end

function Level:update(dt, player)
    for _, room in ipairs(self.rooms) do
        for _, enemy in ipairs(room.enemies) do
            enemy:update(dt, player)
        end
    end
end

return Level