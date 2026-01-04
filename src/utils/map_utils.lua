local MapUtils = {}

function MapUtils:isWalkableTile(map, tx, ty)
    local t = map[ty] and map[ty][tx]

    return t == 1 or t == 4
end

return MapUtils