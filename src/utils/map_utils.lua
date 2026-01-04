local MapUtils = {}

function MapUtils:isWalkableTile(map, tx, ty)
    local t = map[ty] and map[ty][tx]

    return t == TILE_FLOOR or t == TILE_GLASS or t == TILE_CORRIDOR
end

return MapUtils