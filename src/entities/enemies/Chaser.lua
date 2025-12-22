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
    -- Position de l'ennemi
    local ePos = Vector(self.x + self.w/2, self.y + self.h/2)
    -- Position du joueur
    local targetPos = Vector(player.x + player.w/2, player.y + player.h/2)
    local dir = (targetPos - ePos):normalized()

    -- --- LOGIQUE D'ANTICIPATION (Le Radar) ---
    local lookAheadDistance = 50 -- Distance de détection
    local detectorAngle = 0.5    -- Angle des "antennes" (en radians)

    -- On crée deux vecteurs de détection (gauche et droite)
    local rayLeft = dir:rotated(-detectorAngle) * lookAheadDistance
    local rayRight = dir:rotated(detectorAngle) * lookAheadDistance

    -- On teste si un des rayons touche un obstacle via Bump
    -- (On utilise world:querySegment pour "regarder" devant)
    local itemsL, lenL = self.world:querySegment(ePos.x, ePos.y, ePos.x + rayLeft.x, ePos.y + rayLeft.y)
    local itemsR, lenR = self.world:querySegment(ePos.x, ePos.y, ePos.x + rayRight.x, ePos.y + rayRight.y)

    -- On stocke ces vecteurs pour pouvoir les dessiner plus tard
    self.debug_rayL = targetPos + rayLeft
    self.debug_rayR = targetPos + rayRight
    -- On stocke aussi si ça a touché (pour changer la couleur)
    self.debug_hitL = (lenL > 0)
    self.debug_hitR = (lenR > 0)

    local avoidanceForce = Vector(0, 0)

    -- Si le rayon gauche touche un mur, on pousse vers la droite
    if lenL > 0 then
        for i=1, lenL do
            if itemsL[i].type == "wall" or itemsL[i].type == "pillar" then
                avoidanceForce = avoidanceForce + dir:perpendicular()
                break
            end
        end
    end

    -- Si le rayon droit touche un mur, on pousse vers la gauche
    if lenR > 0 then
        for i=1, lenR do
            if itemsR[i].type == "wall" or itemsR[i].type == "pillar" then
                avoidanceForce = avoidanceForce - dir:perpendicular()
                break
            end
        end
    end

    -- --- CALCUL DU MOUVEMENT FINAL ---
    -- On mélange la direction vers le joueur et la force d'évitement
    local finalDir = (dir + avoidanceForce * 1.5):normalized()
    local velocity = finalDir * self.speed * dt

    local goalX, goalY = self.x + velocity.x, self.y + velocity.y

    -- Bump sert maintenant de "filet de sécurité" final
    local ax, ay, cols, len = self.world:move(self, goalX, goalY, WorldUtils.enemyFilter)

    -- 4. Mise à jour des coordonnées
    MathUtils.updateCoordinates(self, ax, ay)
end

return Chaser