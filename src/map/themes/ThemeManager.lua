local ThemeManager = {}

-- Liste officielle des thèmes
ThemeManager.ALL = {
    require "src.map.themes.LabTheme",
    require "src.map.themes.HospitalTheme",
    require "src.map.themes.GraveyardTheme"
}

-- Tire N thèmes distincts
function ThemeManager.pickRandom(rng, count)
    local pool = {}
    for i, t in ipairs(ThemeManager.ALL) do
        pool[i] = t
    end

    local picked = {}

    for i = 1, math.min(count, #pool) do
        local index = rng:random(1, #pool)
        table.insert(picked, pool[index])
        table.remove(pool, index)
    end

    return picked
end

return ThemeManager
