-- Dependancies
local Enemy = require "src.entities.enemies.Enemy"
local Vector = require "libs.hump.vector"
-- Utils
local WorldUtils = require "src.utils.world_utils"
local MathUtils = require "src.utils.math_utils"

local Chaser = Enemy:extend()

function Chaser:new(world, x, y)
    -- HP: 3, Speed: 80
    Chaser.super.new(self, world, x, y, 3, 80)
end

function Chaser:update(dt, player)
    local pPos = Vector(player.x, player.y)
    local ePos = self.pos -- Déjà un vecteur

    -- 2. Calcul du vecteur de direction (Cible - Moi)
    local diff = pPos - ePos

    -- 3. Mouvement : on normalise la direction et on applique la vitesse
    -- .trimmed(1) gère le cas où l'ennemi est pile sur le joueur (distance 0)
    local velocity = diff:trimmed(1) * self.speed * dt
    local goal = ePos + velocity

    -- 4. On demande à Bump de gérer les collisions
    local ax, ay, cols, len = self.world:move(self, goal.x, goal.y, WorldUtils.enemyFilter)

    -- 5. Mise à jour des coordonnées
    MathUtils.updateCoordinates(self, ax, ay)
end

return Chaser