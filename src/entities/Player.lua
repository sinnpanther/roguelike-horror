-- Dependancies
local Vector = require "libs.hump.vector"
-- Utils
local WorldUtils = require "src.utils.world_utils"
local MathUtils = require "src.utils.math_utils"

local Player = Class:extend()

function Player:new(world, x, y)
    self.world = world
    -- Initial position and dimensions
    self.x, self.y = x, y
    self.pos = Vector(x, y)
    self.w, self.h = 32, 32 -- Rectangle size for collision
    self.type = "player"

    -- Movement settings
    self.speed = 300
    self.angle = 0 -- Direction de la lampe
    self.moveDir = Vector(0, 0)

    -- Horror mechanics
    self.fear = 0
    self.fearGain = 5

    -- L'entité s'ajoute elle-même au monde
    self.world:add(self, self.pos.x, self.pos.y, self.w, self.h)
end

function Player:update(dt)
    local dir = self.moveDir
    dir.x, dir.y = 0, 0

    -- Handle keyboard inputs (WASD / ZQSD support)
    if love.keyboard.isDown("z") or love.keyboard.isDown("up") then dir.y = dir.y - 1 end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then dir.y = dir.y + 1 end
    if love.keyboard.isDown("q") or love.keyboard.isDown("left") then dir.x = dir.x - 1 end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then dir.x = dir.x + 1 end

    -- Mise à jour de l'angle seulement si on bouge
    if dir:len() > 0 then
        self.angle = math.atan2(dir.y, dir.x)
    end

    -- 2. Normalisation et vitesse
    -- .trimmed(1) est une super fonction de HUMP qui normalise seulement
    -- si la longueur > 1 (évite les divisions par zéro et les bugs)
    local velocity = dir:trimmed(1) * self.speed * dt

    -- 3. Calcul de la destination
    local goal = self.pos + velocity

    -- 4. Bump
    local ax, ay, cols, len = self.world:move(self, goal.x, goal.y, WorldUtils.playerFilter)

    -- 5. Mise à jour (on synchronise le vecteur et les variables x,y classiques)
    MathUtils.updateCoordinates(self, ax, ay)

    --for i = 1, len do
    --    local col = cols[i]
    --    if col.other.isItem then
    --        -- We touched an item!
    --        self:pickup(col.other, world)
    --    end
    --end

    -- Si le joueur ne bouge pas (dx et dy sont à 0), l'angoisse monte plus vite !
    --if dx == 0 and dy == 0 then
    --    self.fear = math.min(100, self.fear + self.fearGain * dt)
    --end

    for i=1, len do
        local col = cols[i]
        if col.other.onInteract then
            col.other:onInteract(self)
        end
    end
end

function Player:draw()
    -- Draw player placeholder
    love.graphics.setColor(0.2, 0.6, 1) -- Light blue
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    -- Reset color to avoid tinting other objects
    love.graphics.setColor(1, 1, 1)
end

return Player