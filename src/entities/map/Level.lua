-- src/entities/map/Level.lua
local Room = require "src.entities.map.Room"
local WorldUtils = require "src.utils.world_utils"

local Level = Class:extend()

local CORRIDOR_WIDTH = 2

function Level:new(world, seed, levelIndex)
    self.world = world
    self.seed = seed
    self.levelIndex = levelIndex

    self.rng = love.math.newRandomGenerator(seed + levelIndex)

    self.ts = TILE_SIZE
    self.mapW, self.mapH = 200, 160 -- en tiles (à ajuster)
    self.tiles = {}
    self.rooms = {}
    self.walls = {}
end

function Level:generate()
    self:_initTiles(1) -- 1 = mur partout

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
    -- debug draw sol/mur (optionnel)
    -- puis dessiner walls + rooms contents
    love.graphics.setColor(0.1, 0.1, 0.1)
    for y = 1, self.mapH do
        for x = 1, self.mapW do
            if self.tiles[y][x] == 0 then
                love.graphics.rectangle("fill", (x-1)*self.ts, (y-1)*self.ts, self.ts, self.ts)
            end
        end
    end

    love.graphics.setColor(0.6, 0.6, 0.7)
    for _, wall in ipairs(self.walls) do
        love.graphics.rectangle("fill", wall.x, wall.y, wall.w, wall.h)
    end
end

function Level:_initTiles(fillValue)
    for y = 1, self.mapH do
        self.tiles[y] = {}
        for x = 1, self.mapW do
            self.tiles[y][x] = fillValue
        end
    end
end

function Level:_placeRooms(targetCount)
    local attempts = 0
    local maxAttempts = targetCount * 40

    while #self.rooms < targetCount and attempts < maxAttempts do
        attempts = attempts + 1

        local w = self.rng:random(20, 28)
        local h = self.rng:random(18, 24)
        local x = self.rng:random(2, self.mapW - w - 1)
        local y = self.rng:random(2, self.mapH - h - 1)

        local rect = { x = x, y = y, w = w, h = h }

        if not self:_rectOverlapsAny(rect, 2) then
            self:_carveRoom(rect)
            table.insert(self.rooms, Room(self.world, self.rng, self.levelIndex, rect))
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
            self.tiles[y][x] = 0 -- sol
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
        self.tiles[y][x] = 0
        -- largeur de couloir optionnelle
        self.tiles[y+1][x] = 0
    end
end

function Level:_carveV(y1, y2, x)
    local from = math.min(y1, y2)
    local to   = math.max(y1, y2)
    for y = from, to do
        self.tiles[y][x] = 0
        -- largeur optionnelle
        self.tiles[y][x+1] = 0
    end
end

function Level:_buildWallColliders()
    -- Très simple: pour chaque tile mur (1) adjacent à un sol (0), on place un collider.
    -- (Optimisation plus tard: merge rectangles)
    for y = 1, self.mapH do
        for x = 1, self.mapW do
            if self.tiles[y][x] == 1 and self:_hasAdjacentFloor(x, y) then
                local px = (x-1) * self.ts
                local py = (y-1) * self.ts
                WorldUtils.addWall(self.world, self.walls, px, py, self.ts, self.ts)
            end
        end
    end
end

function Level:_hasAdjacentFloor(x, y)
    local function isFloor(tx, ty)
        if tx < 1 or tx > self.mapW or ty < 1 or ty > self.mapH then return false end
        return self.tiles[ty][tx] == 0
    end
    return isFloor(x+1,y) or isFloor(x-1,y) or isFloor(x,y+1) or isFloor(x,y-1)
end

function Level:update(dt, player)
    for _, room in ipairs(self.rooms) do
        for _, enemy in ipairs(room.enemies) do
            enemy:update(dt, player)
        end
    end
end

return Level