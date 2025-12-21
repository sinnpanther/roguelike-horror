-- src/utils/world_utils.lua
local WorldUtils = {}

function WorldUtils.addWall(world, wallList, x, y, w, h)
    local wall = { x = x, y = y, w = w, h = h, type = "wall" }
    table.insert(wallList, wall)
    world:add(wall, x, y, w, h)
    return wall
end

-- NOUVELLE FONCTION : Pour vider proprement la salle précédente
function WorldUtils.clearWorld(world)
    local items = world:getItems()
    -- On boucle à l'envers pour éviter les problèmes d'index lors de la suppression
    for i = #items, 1, -1 do
        local item = items[i]
        if item.type ~= "player" then
            world:remove(item)
        end
    end
end

function WorldUtils.playerFilter(item, other)
    if other.type == "door" then
        return "cross"
    end

    return "slide"
end

return WorldUtils