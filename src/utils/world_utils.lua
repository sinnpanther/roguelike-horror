-- src/utils/world_utils.lua
local WorldUtils = {}

function WorldUtils.addWall(world, wallList, x, y, w, h)
    local wall = { x = x, y = y, w = w, h = h, type = "wall" }
    table.insert(wallList, wall)
    world:add(wall, x, y, w, h)
    return wall
end

-- Vider proprement la salle précédente
function WorldUtils.clearWorld(world)
    local items = world:getItems()
    -- On boucle à l'envers pour éviter les problèmes d'index lors de la suppression
    for i = #items, 1, -1 do
        local item = items[i]
        if item.entityType ~= "player" then
            world:remove(item)
        end
    end
end

function WorldUtils.playerFilter(item, other)
    if other.entityType == "enemy" then
        return "cross"
    end

    return "slide"
end

function WorldUtils.enemyFilter(item, other)
    if other.entityType == "player" then
        return "cross" -- On passe à travers le joueur, mais Bump enregistre la collision
    elseif other.entityType == "enemy" then
        return "slide" -- Optionnel : les ennemis se bloquent entre eux
    end

    return "slide" -- Bloqué par le reste
end

function WorldUtils.debugMap(map)
    local lines = {}

    for y = 1, #map do
        local row = {}
        for x = 1, #map[y] do
            table.insert(row, tostring(map[y][x]))
        end
        table.insert(lines, table.concat(row, " "))
    end

    local output = table.concat(lines, "\n")

    -- Print dans la console (optionnel)
    --print(output)

    -- Copie directe dans le presse-papier
    love.system.setClipboardText(output)
end

return WorldUtils