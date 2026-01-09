-- src/utils/vision_utils.lua
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
    local dx = bx - ax
    local dy = by - ay

    local dist = math.sqrt(dx * dx + dy * dy)
    if dist <= 0.0001 then
        return true
    end

    local dirX = dx / dist
    local dirY = dy / dist

    local invDx = (dirX ~= 0) and (1 / dirX) or 1e12
    local invDy = (dirY ~= 0) and (1 / dirY) or 1e12

    -- position en tuiles continues (0-based)
    local gx = ax / ts
    local gy = ay / ts

    local tx = math.floor(gx)
    local ty = math.floor(gy)

    local stepX = (dirX >= 0) and 1 or -1
    local stepY = (dirY >= 0) and 1 or -1

    local nextGridX = (stepX == 1) and (tx + 1) or tx
    local nextGridY = (stepY == 1) and (ty + 1) or ty

    local tMaxX = (nextGridX - gx) * ts * invDx
    local tMaxY = (nextGridY - gy) * ts * invDy

    local tDeltaX = ts * math.abs(invDx)
    local tDeltaY = ts * math.abs(invDy)

    local eps = epsilonPixels or 1.0
    local traveled = 0

    -- On traverse la grille jusqu’à atteindre la distance du segment
    while traveled <= dist do
        local tEnter

        if tMaxX < tMaxY then
            tx = tx + stepX
            tEnter = tMaxX
            tMaxX = tMaxX + tDeltaX
        else
            ty = ty + stepY
            tEnter = tMaxY
            tMaxY = tMaxY + tDeltaY
        end

        traveled = tEnter

        -- Si on est quasiment arrivé, on considère la vue dégagée
        if traveled >= dist - eps then
            return true
        end

        local mapX = tx + 1
        local mapY = ty + 1

        if VisionUtils.isWall(level, mapX, mapY) then
            return false
        end
    end

    return true
end

return VisionUtils