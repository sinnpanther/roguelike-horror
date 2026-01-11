local DebugFlags = require "src.debug.DebugFlags"

local SpatialHash = Class:extend()

function SpatialHash:new(cellSize)
    self.cellSize = cellSize or 64
    self.cells = {} -- { ["x:y"] = { entity1, entity2, ... } }
end

-- --------------------------------------------------
-- Utils internes
-- --------------------------------------------------

local function cellKey(cx, cy)
    return cx .. ":" .. cy
end

function SpatialHash:_getCellCoords(x, y)
    return math.floor(x / self.cellSize), math.floor(y / self.cellSize)
end

-- --------------------------------------------------
-- Gestion des entités
-- --------------------------------------------------

-- Ajoute une entité (doit avoir x, y, w, h)
function SpatialHash:add(entity)
    local minX, minY = self:_getCellCoords(entity.x, entity.y)
    local maxX, maxY = self:_getCellCoords(
            entity.x + entity.w,
            entity.y + entity.h
    )

    entity._spatialCells = {}

    for cy = minY, maxY do
        for cx = minX, maxX do
            local key = cellKey(cx, cy)
            self.cells[key] = self.cells[key] or {}
            table.insert(self.cells[key], entity)
            table.insert(entity._spatialCells, key)
        end
    end
end

-- Retire une entité
function SpatialHash:remove(entity)
    if not entity._spatialCells then return end

    for _, key in ipairs(entity._spatialCells) do
        local cell = self.cells[key]
        if cell then
            for i = #cell, 1, -1 do
                if cell[i] == entity then
                    table.remove(cell, i)
                end
            end
            if #cell == 0 then
                self.cells[key] = nil
            end
        end
    end

    entity._spatialCells = nil
end

-- À appeler quand une entité bouge
function SpatialHash:update(entity)
    self:remove(entity)
    self:add(entity)
end

-- --------------------------------------------------
-- Requêtes
-- --------------------------------------------------

-- Récupère les entités proches d'un rectangle
function SpatialHash:queryRect(x, y, w, h, filter)
    local minX, minY = self:_getCellCoords(x, y)
    local maxX, maxY = self:_getCellCoords(x + w, y + h)

    -- Entités retournées
    local results = {}
    -- Evite les doublons, une entité peut être dans plusieurs cellules
    local seen = {}

    for cy = minY, maxY do
        for cx = minX, maxX do
            local cell = self.cells[cellKey(cx, cy)]
            if cell then
                for _, e in ipairs(cell) do
                    if not seen[e] then
                        seen[e] = true

                        if not filter or filter(e) then
                            table.insert(results, e)
                        end
                    end
                end
            end
        end
    end

    return results
end

-----------------------------------------------------
-- Debug
-----------------------------------------------------
function SpatialHash:debug()
    if not DebugFlags.enabled and not DebugFlags.spatialHash.enabled then
        return
    end

    love.graphics.setColor(0, 1, 0, 1)

    for key, _ in pairs(self.cells) do
        local cx, cy = key:match("([^:]+):([^:]+)")
        cx, cy = tonumber(cx), tonumber(cy)

        love.graphics.rectangle(
                "line",
                cx * self.cellSize,
                cy * self.cellSize,
                self.cellSize,
                self.cellSize
        )
    end

    StyleUtils.resetColor()
end

return SpatialHash
