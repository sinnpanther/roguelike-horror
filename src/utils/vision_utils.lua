local Vector = require "libs.hump.vector"

local VisionUtils = {}

--------------------------------------------------
-- Helpers
--------------------------------------------------
function VisionUtils.isWall(level, tx, ty)
    local map = level.map
    if not map[ty] or not map[ty][tx] then
        return true -- hors map = bloquant
    end
    return map[ty][tx] == TILE_WALL or map[ty][tx] == TILE_PROP
end

--------------------------------------------------
-- DDA Line Of Sight (segment ax,ay -> bx,by)
-- Retourne true si aucune tuile mur (2) ne bloque la vue.
--
-- epsilonPixels:
--   - augmente (1.5..2) si scintillement sur coins
--   - diminue (0.5) si tu veux coller plus près des murs
--------------------------------------------------
function VisionUtils.hasLineOfSight(level, ax, ay, bx, by, epsilonPixels)
    local ts = TILE_SIZE
    local eps = epsilonPixels or 1.0

    -- Vecteur A -> B
    local ray = Vector(bx - ax, by - ay)
    local dist = ray:len()

    if dist <= 0.0001 then
        return true
    end

    local dir = ray / dist

    -- Inverses sécurisés
    local invDx = (math.abs(dir.x) > 1e-8) and (1 / dir.x) or math.huge
    local invDy = (math.abs(dir.y) > 1e-8) and (1 / dir.y) or math.huge

    -- Position continue en coordonnées de grille
    local gx = ax / ts
    local gy = ay / ts

    local tx = math.floor(gx)
    local ty = math.floor(gy)

    local stepX = (dir.x >= 0) and 1 or -1
    local stepY = (dir.y >= 0) and 1 or -1

    local nextGridX = (stepX == 1) and (tx + 1) or tx
    local nextGridY = (stepY == 1) and (ty + 1) or ty

    local tMaxX = (nextGridX - gx) * ts * invDx
    local tMaxY = (nextGridY - gy) * ts * invDy

    local tDeltaX = ts * math.abs(invDx)
    local tDeltaY = ts * math.abs(invDy)

    local traveled = 0

    while traveled <= dist do
        if tMaxX < tMaxY then
            tx = tx + stepX
            traveled = tMaxX
            tMaxX = tMaxX + tDeltaX
        else
            ty = ty + stepY
            traveled = tMaxY
            tMaxY = tMaxY + tDeltaY
        end

        -- Fin de segment
        if traveled >= dist - eps then
            return true
        end

        -- Passage en coordonnées carte (1-based)
        local mapX = tx + 1
        local mapY = ty + 1

        if VisionUtils.isWall(level, mapX, mapY) then
            return false
        end
    end

    return true
end

return VisionUtils