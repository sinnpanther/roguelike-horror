local HospitalLayout = require "src.map.layouts.HospitalLayout"
local LabLayout = require "src.map.layouts.LabLayout"

local LayoutFactory = {}

function LayoutFactory.create(profile, level)
    local name = profile.layout
    local seed = level.rng:random(1, 2^30)

    if name == "hospital" then
        return HospitalLayout(level, profile, seed)
    end

    if name == "laboratory" then
        return LabLayout(level, profile, seed)
    end

    error("Unknown layout: " .. tostring(name))
end

return LayoutFactory
