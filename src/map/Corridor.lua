local Corridor = Class:extend()

function Corridor:new(corridorSeed, level, profile)
    self.rng = love.math.newRandomGenerator(corridorSeed)
    self.rooms = level.rooms
    self.map = level.map
    self.profile = profile
end

function Corridor:build()
    if self.profile.layout == "laboratory" then
        self:_buildLaboratory()
    elseif self.profile.layout == "hub" then
        self:_buildHub()
    elseif self.profile.layout == "arena" then
        -- pas de corridors
    end
end

function Corridor:_buildLaboratory()
    -- connect rooms (simple: chain)
    table.sort(self.rooms, function(a,b) return a:centerX() < b:centerX() end)
    for i = 2, #self.rooms do
        local ax, ay = self.rooms[i-1]:centerTile()
        local bx, by = self.rooms[i]:centerTile()
        self:_carve(ax, ay, bx, by)
    end
end

function Corridor:_buildHub()
    ---- connect rooms (hub)
    --local centerRoom = self.rooms[math.floor(#self.rooms / 2)]
    --local centerTileX, centerTileY = centerRoom:centerTile()
    --for _, room in ipairs(self.rooms) do
    --    local tileX, tileY = room:centerTile()
    --    self:_carve(centerTileX, centerTileY, tileX, tileY)
    --end
end

function Corridor:_carve(ax, ay, bx, by)
    -- couloir en L : horizontal puis vertical (ou l'inverse aléatoire)
    if self.rng:random(1, 2) == 1 then
        self:_carveH(ax, bx, ay)
        self:_carveV(ay, by, bx)
    else
        self:_carveV(ay, by, ax)
        self:_carveH(ax, bx, by)
    end
end

function Corridor:_carveH(x1, x2, y)
    local from = math.min(x1, x2)
    local to   = math.max(x1, x2)
    for x = from, to do
        self.map[y][x] = TILE_CORRIDOR
        -- largeur de couloir optionnelle
        self.map[y+1][x] = TILE_CORRIDOR
    end
end

function Corridor:_carveV(y1, y2, x)
    local from = math.min(y1, y2)
    local to   = math.max(y1, y2)
    for y = from, to do
        self.map[y][x] = TILE_CORRIDOR
        -- largeur optionnelle
        self.map[y][x+1] = TILE_CORRIDOR
    end
end

return Corridor