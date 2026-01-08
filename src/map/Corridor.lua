local Corridor = Class:extend()

function Corridor:new(corridorSeed, level, profile, data)
    self.rng = love.math.newRandomGenerator(corridorSeed)
    self.level = level
    self.rooms = level.rooms
    self.map = level.map
    self.profile = profile
    self.data = data or {}
end

function Corridor:build()
    if self.profile.layout == "laboratory" then
        self:_buildLaboratory()
    elseif self.profile.layout == "hospital" then
        self:_buildHospital()
    --elseif self.profile.layout == "arena" then
        -- pas de corridors
    end
end

--------------------------------------------------
-- LABORATORY
--------------------------------------------------
function Corridor:_buildLaboratory()
    -- connect rooms (simple: chain)
    table.sort(self.rooms, function(a,b) return a:centerX() < b:centerX() end)
    for i = 2, #self.rooms do
        local ax, ay = self.rooms[i-1]:centerTile()
        local bx, by = self.rooms[i]:centerTile()
        self:_carve(ax, ay, bx, by)
    end
end

--------------------------------------------------
-- HOSPITAL
--------------------------------------------------
function Corridor:_buildHospital()
    local rooms = self.rooms
    if #rooms == 0 then
        return
    end

    local data = self.data
    if not data then
        error("Hospital corridor data are missing.")
    end

    local corridorY = data.y
    local side = data.side

    local width = self.profile.corridorWidth or 2

    local extra = self.rng:random(
            self.profile.corridorExtraLength.min,
            self.profile.corridorExtraLength.max
    )

    local first = rooms[1].rect
    local last = rooms[#rooms].rect

    local fromX = math.max(1, first.x - extra)
    local toX = math.min(self.level.mapW - 1, last.x + last.w - 1 + extra)

    --------------------------------------------------
    -- MAIN HORIZONTAL CORRIDOR
    --------------------------------------------------
    for y = corridorY, corridorY + width - 1 do
        for x = fromX, toX do
            self.map[y][x] = TILE_CORRIDOR
        end
    end

    --------------------------------------------------
    -- ROOM CONNECTIONS
    --------------------------------------------------
    for _, room in ipairs(rooms) do
        self:_connectRoomToHospitalCorridor(room, corridorY, side, width)
    end
end

function Corridor:_connectRoomToHospitalCorridor(room, corridorY, side, width)
    local doorX = math.floor(room.rect.x + room.rect.w / 2)

    local fromY, toY

    if side == "top" then
        fromY = corridorY + width
        toY = room.rect.y
    else
        fromY = room.rect.y + room.rect.h
        toY = corridorY
    end

    for y = fromY, toY do
        self.map[y][doorX] = TILE_FLOOR
        self.map[y][doorX + 1] = TILE_FLOOR
    end
end

--------------------------------------------------
-- GENERIC CARVING
--------------------------------------------------
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