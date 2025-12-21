local MathUtils = {}

-- Generate a random string in Base 36 (0-9, A-Z)
function MathUtils.generateBase36Seed(length)
    local chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local seed = ""
    for i = 1, length do
        local rand = love.math.random(1, #chars)
        seed = seed .. chars:sub(rand, rand)
    end
    return seed
end

-- Hash a string into a numeric seed using a simple polynomial rolling hash
-- This ensures the number fits within safe integer limits
function MathUtils.hashString(str)
    local hash = 0
    for i = 1, #str do
        -- 31 is a standard prime number for hashing
        -- We use % 2^30 to keep the number within safe Lua integer limits
        hash = (hash * 31 + str:byte(i)) % 1073741824
    end
    return hash
end

return MathUtils