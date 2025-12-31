-- Dependancies
local Room = require "src.map.Room"
local SpatialHash = require "src.map.SpatialHash"

-- Utils
local WorldUtils = require "src.utils.world_utils"

local Level = Class:extend()

function Level:new(world, seed, levelIndex)
    self.world = world
    self.seed = seed
    self.levelIndex = levelIndex
    self.spatialHash = SpatialHash(TILE_SIZE * 2)

    self.rng = love.math.newRandomGenerator(seed + levelIndex)

    self.ts = TILE_SIZE
    self.mapW, self.mapH = 200, 160 -- en tiles (à ajuster)

    -- Map
    -- 0 = Vide
    -- 1 = Sol
    -- 2 = Mur
    self.map = {}
    self.rooms = {}
    self.walls = {}

    self.tileset = love.graphics.newImage("assets/graphics/tiles/tileset.png")
    self.tileset:setFilter("nearest", "nearest")
end

function Level:generate()
    self:_initTiles(0)

    local roomCount = self.rng:random(2, 5) -- exemple
    self:_placeRooms(roomCount)

    -- connect rooms (simple: chain)
    table.sort(self.rooms, function(a,b) return a:centerX() < b:centerX() end)
    for i = 2, #self.rooms do
        local ax, ay = self.rooms[i-1]:centerTile()
        local bx, by = self.rooms[i]:centerTile()
        self:_carveCorridorL(ax, ay, bx, by)
    end

    self:_buildWallColliders()

    -- spawn ennemis / deco par room
    for _, room in ipairs(self.rooms) do
        room:spawnEnemies()
        -- room:spawnPillars() etc (si tu veux)
    end

    -- si tu veux garder un équivalent "segments"
    self.segments = self.rooms
    self.mainRoom = self.rooms[1]
end

function Level:draw()
    for y = 1, self.mapH do
        for x = 1, self.mapW do
            local tile = self.map[y][x]
            local px = (x - 1) * TILE_SIZE
            local py = (y - 1) * TILE_SIZE

            -- SOL
            if tile == 1 then
                local quad = love.graphics.newQuad(32, 32, self.ts, self.ts, self.tileset:getWidth(), self.tileset:getHeight())
                love.graphics.draw(self.tileset, quad, px, py)
            end

            -- MUR
            if tile == 2 then
                local quad = love.graphics.newQuad(0, 256, self.ts, self.ts, self.tileset:getWidth(), self.tileset:getHeight())
                love.graphics.draw(self.tileset, quad, px, py)
            end
        end
    end

    for _, room in ipairs(self.rooms) do
        for _, enemy in ipairs(room.enemies) do
            enemy:draw()
        end
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

function Level:_placeRooms(roomCount)
    local maxAttempts = roomCount * 40
    local attempts = 0

    while #self.rooms < roomCount and attempts < maxAttempts do
        attempts = attempts + 1

        local w = self.rng:random(20, 28)
        local h = self.rng:random(18, 24)
        -- Zone centrale plus dense
        local marginX = math.floor(self.mapW * 0.25)
        local marginY = math.floor(self.mapH * 0.25)

        local x = self.rng:random(marginX, self.mapW - marginX - w)
        local y = self.rng:random(marginY, self.mapH - marginY - h)

        local rect = { x = x, y = y, w = w, h = h }

        if not self:_rectOverlapsAny(rect, 3) then
            self:_carveRoom(rect)
            table.insert(self.rooms, Room(self.world, self, self.rng, self.levelIndex, rect))
        end
    end
end

function Level:_rectOverlapsAny(rect, padding)
    for _, r in ipairs(self.rooms) do
        local a = rect
        local b = r.rect
        if self:_rectsOverlap(a, b, padding) then
            return true
        end
    end
    return false
end

function Level:_rectsOverlap(a, b, padding)
    local p = padding or 0
    return not (
        a.x + a.w + p < b.x or
        a.x > b.x + b.w + p or
        a.y + a.h + p < b.y or
        a.y > b.y + b.h + p
    )
end

function Level:_carveRoom(rect)
    for y = rect.y, rect.y + rect.h - 1 do
        for x = rect.x, rect.x + rect.w - 1 do
            self.map[y][x] = 1 -- sol
        end
    end
end

function Level:_carveCorridorL(ax, ay, bx, by)
    -- couloir en L : horizontal puis vertical (ou l'inverse aléatoire)
    if self.rng:random(1, 2) == 1 then
        self:_carveH(ax, bx, ay)
        self:_carveV(ay, by, bx)
    else
        self:_carveV(ay, by, ax)
        self:_carveH(ax, bx, by)
    end
end

function Level:_carveH(x1, x2, y)
    local from = math.min(x1, x2)
    local to   = math.max(x1, x2)
    for x = from, to do
        self.map[y][x] = 1
        -- largeur de couloir optionnelle
        self.map[y+1][x] = 1
    end
end

function Level:_carveV(y1, y2, x)
    local from = math.min(y1, y2)
    local to   = math.max(y1, y2)
    for y = from, to do
        self.map[y][x] = 1
        -- largeur optionnelle
        self.map[y][x+1] = 1
    end
end

function Level:_buildWallColliders()
    for y = 1, self.mapH do
        for x = 1, self.mapW do
            if self.map[y][x] == 0 then
                if self:_hasAdjacentFloor(x, y) then
                    local px = (x-1) * self.ts
                    local py = (y-1) * self.ts

                    WorldUtils.addWall(self.world, self.walls, px, py, self.ts, self.ts)
                    self.map[y][x] = 2
                end
            end
        end
    end
end

function Level:_hasAdjacentFloor(x, y)
    local function isFloor(tx, ty)
        if tx < 1 or tx > self.mapW or ty < 1 or ty > self.mapH then
            return false
        end
        return self.map[ty][tx] == 1
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

function Level:buildQuads()
    self.quads = {}

    for y = 1, self.mapH do
        self.quads[y] = {}
        for x = 1, self.mapW do
            if self.map[y][x] == 2 then
                self.quads[y][x] = AutoTile.getQuad(
                        self.map,
                        x,
                        y,
                        self.tileset
                )
            end
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