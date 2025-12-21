-- src/utils/world_utils.lua
local WorldUtils = {}

function WorldUtils.addWall(world, wallList, x, y, w, h)
    local wall = { x = x, y = y, w = w, h = h, type = "wall" }
    table.insert(wallList, wall)
    world:add(wall, x, y, w, h)
    return wall
end

-- NOUVELLE FONCTION : Pour vider proprement la salle précédente
function WorldUtils.clearWorld(world, wallList)
    -- On retire chaque mur du monde physique Bump
    for _, wall in ipairs(wallList) do
        if world:hasItem(wall) then
            world:remove(wall)
        end
    end
    -- On vide la table Lua pour le dessin
    for i = 1, #wallList do wallList[i] = nil end
end

function WorldUtils.playerFilter(item, other)
    if other.type == "wall" then return "slide" end
    return "cross"
end

return WorldUtils