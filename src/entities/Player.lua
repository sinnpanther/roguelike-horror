-- Utils
local WorldUtils = require "src.utils.world_utils"

local Player = Class:extend()

function Player:new(x, y)
    -- Initial position and dimensions
    self.x, self.y = x, y
    self.w, self.h = 32, 32 -- Rectangle size for collision

    -- Movement settings
    self.speed = 300

    -- Horror mechanics initial state
    self.fear = 0
    self.fearGain = 5
    self.lightRadius = 200 -- The size of our light circle
end

function Player:update(dt, world)
    local dx, dy = 0, 0

    -- Handle keyboard inputs (WASD / ZQSD support)
    if love.keyboard.isDown("z") or love.keyboard.isDown("up") then dy = -1 end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then dy = 1 end
    if love.keyboard.isDown("q") or love.keyboard.isDown("left") then dx = -1 end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then dx = 1 end

    -- Normalize diagonal movement speed
    -- This prevents the player from moving ~1.41x faster when holding two keys
    if dx ~= 0 and dy ~= 0 then
        local length = math.sqrt(dx^2 + dy^2)
        dx = dx / length
        dy = dy / length
    end

    -- Calculate the desired target position
    local goalX = self.x + dx * self.speed * dt
    local goalY = self.y + dy * self.speed * dt

    -- Bump.lua movement: checks for collisions and returns the final allowed position
    -- 'cols' contains all collision data (which wall was hit, from which side, etc.)
    local actualX, actualY, cols, len = world:move(self, goalX, goalY, "WorldUtils.playerFilter")
    -- Update internal coordinates with the validated position
    self.x, self.y = actualX, actualY

    for i = 1, len do
        local col = cols[i]
        if col.other.isItem then
            -- We touched an item!
            self:pickup(col.other, world)
        end
    end

    -- Si le joueur ne bouge pas (dx et dy sont à 0), l'angoisse monte plus vite !
    if dx == 0 and dy == 0 then
        self.fear = math.min(100, self.fear + self.fearGain * dt)
    end
end

function Player:pickup(item, world)
    if item.type == "sedative" then
        self.fear = math.max(0, self.fear - 30) -- Reduce fear by 30 points
    end
    -- Remove the item from the physical world so we don't pick it up twice
    world:remove(item)
    item.isPickedUp = true -- Mark it for removal from the draw list
end

function Player:draw()
    -- Draw player placeholder
    love.graphics.setColor(0.2, 0.6, 1) -- Light blue
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    -- Reset color to avoid tinting other objects
    love.graphics.setColor(1, 1, 1)
end

return Player