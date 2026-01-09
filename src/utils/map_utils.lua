local MapUtils = {}

function MapUtils:isWalkableTile(map, tx, ty)
    local t = map[ty] and map[ty][tx]

    return t == TILE_FLOOR or t == TILE_GLASS or t == TILE_CORRIDOR
end

function MapUtils:isFreeTile(map, tx, ty)
    local t = map[ty] and map[ty][tx]

    return t == TILE_FLOOR or t == TILE_CORRIDOR
end

-- Retourne un point monde (px, py) aléatoire dans une room
-- - évite les bords
-- - uniquement sur tiles marchables
function MapUtils.getRandomPointInRoom(level, room, rng, margin)
    margin = margin or 2

    local map = level.map
    local ts = TILE_SIZE

    local minX = room.rect.x + margin
    local maxX = room.rect.x + room.rect.w - margin - 1
    local minY = room.rect.y + margin
    local maxY = room.rect.y + room.rect.h - margin - 1

    local maxAttempts = 30

    for _ = 1, maxAttempts do
        local tx = rng:random(minX, maxX)
        local ty = rng:random(minY, maxY)

        if MapUtils:isFreeTile(map, tx, ty) then
            local px = (tx - 0.5) * ts
            local py = (ty - 0.5) * ts

            return px, py
        end
    end

    -- fallback : centre de la room
    local cx = (room.rect.x + room.rect.w / 2 - 0.5) * ts
    local cy = (room.rect.y + room.rect.h / 2 - 0.5) * ts
    return cx, cy
end


return MapUtils