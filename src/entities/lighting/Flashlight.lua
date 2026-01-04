local Flashlight = Class:extend()

--------------------------------------------------
-- CONSTRUCTOR
--------------------------------------------------
function Flashlight:new(player)
    self.player = player

    -- Position monde
    self.x = 0
    self.y = 0

    -- Angles
    self.angle = 0          -- angle réel (rendu)
    self.targetAngle = 0    -- angle cible (input)

    -- Paramètres du cône
    self.coneAngle = math.rad(28)
    self.circle = 40
    self.baseRange = 420
    self.range = self.baseRange

    self.raySmoothPasses = 1      -- 0 = brut, 1 = mieux, 2 = très lisse
    self.rayEpsilon = 2.0         -- évite les pixels noirs au contact
    self.castRays = 96                 -- base
    self.refinePasses = 2              -- 1..3 (2 est un bon sweet spot)
    self.refineDistThreshold = TILE_SIZE * 0.75 -- si gros saut de distance -> on raffine

    -- Jitter vertical (respiration)
    self.jitterTime = 0
    self.rangeJitterAmp = 1     -- intensité (pixels)
    self.rangeJitterSpeed = 20  -- vitesse de respiration

    -- Bords irréguliers
    self.edgeNoiseTime = 0
    self.edgeNoiseSpeed = 0.5      -- vitesse de vie du bord
    self.edgeNoiseAmp   = math.rad(1.2) -- irrégularité angulaire
    self.edgeSegments   = 64       -- précision du bord
end

--------------------------------------------------
-- UPDATE
--------------------------------------------------
function Flashlight:update(dt, cam)
    -- Position = centre du joueur
    local px, py = self.player:getCenter()
    self.x = px
    self.y = py

    -- Angle stable
    local mx, my = love.mouse.getPosition()
    mx, my = cam:worldCoords(mx, my)
    self.angle = math.atan2(my - py, mx - px)

    -- Temps
    self.jitterTime = self.jitterTime + dt

    -- Jitter vertical (portée)
    local breathe = math.sin(self.jitterTime * self.rangeJitterSpeed)
    self.range = self.baseRange + breathe * self.rangeJitterAmp

    -- Animation du bord
    self.edgeNoiseTime = self.edgeNoiseTime + dt * self.edgeNoiseSpeed
end

--------------------------------------------------
-- GETTERS
--------------------------------------------------
function Flashlight:getPosition()
    return self.x, self.y
end

function Flashlight:getAngle()
    return self.angle
end

function Flashlight:getRange()
    return self.range
end

function Flashlight:getCone()
    return self.coneAngle
end

function Flashlight:getCircle()
    return self.circle
end

--------------------------------------------------
-- Cône irrégulier + BLOQUÉ PAR LES MURS (raycast par segment)
-- level: pour accéder à level.map
-- radiusOffset: optionnel (pour debug/halo, mais tu peux laisser 0)
--------------------------------------------------
function Flashlight:drawIrregularCone(level, radiusOffset, alpha)
    local x, y = self.x, self.y
    local a = self.angle
    local maxR = self.range + (radiusOffset or 0)
    local cone = self.coneAngle

    if alpha then
        love.graphics.setColor(0, 0, 0, alpha)
    end

    local function castAt(t)
        -- t in [0..1] le long du cône
        local baseAngle = a - cone + t * cone * 2

        -- (optionnel) bords vivants : perso je conseille de le garder faible
        local noise = math.sin(self.edgeNoiseTime + t * 6.1) * math.cos(self.edgeNoiseTime * 0.7 + t * 3.7)
        local finalAngle = baseAngle + noise * self.edgeNoiseAmp

        local dist, hitTx, hitTy = self:_raycastToWallDDA(level, x, y, finalAngle, maxR)
        return finalAngle, dist, hitTx, hitTy
    end

    -- 1) rays de base
    local rays = self.castRays or self.edgeSegments
    local samples = {}

    for i = 0, rays do
        local t = i / rays
        local ang, dist, hx, hy = castAt(t)
        samples[#samples+1] = { t=t, ang=ang, dist=dist, hx=hx, hy=hy }
    end

    -- 2) raffinement adaptatif (coins)
    local passes = self.refinePasses or 0
    local distThresh = self.refineDistThreshold or (TILE_SIZE * 0.75)

    for _ = 1, passes do
        local refined = {}
        refined[#refined+1] = samples[1]

        for i = 1, #samples - 1 do
            local s1 = samples[i]
            local s2 = samples[i+1]

            local tileChanged = (s1.hx ~= s2.hx) or (s1.hy ~= s2.hy)
            local bigJump = math.abs(s1.dist - s2.dist) > distThresh

            if tileChanged or bigJump then
                local midT = (s1.t + s2.t) * 0.5
                local ang, dist, hx, hy = castAt(midT)
                refined[#refined+1] = { t=midT, ang=ang, dist=dist, hx=hx, hy=hy }
            end

            refined[#refined+1] = s2
        end

        samples = refined
    end

    -- 3) polygone final
    local points = { x + 0.5, y + 0.5 }

    for i = 1, #samples do
        local ang = samples[i].ang
        local dist = samples[i].dist
        local px = x + math.cos(ang) * dist + 0.5
        local py = y + math.sin(ang) * dist + 0.5
        table.insert(points, px)
        table.insert(points, py)
    end

    love.graphics.polygon("fill", points)
end

--------------------------------------------------
-- INTERNAL: map helpers
--------------------------------------------------
function Flashlight:_isWall(level, tx, ty)
    local map = level.map
    if not map[ty] or not map[ty][tx] then
        return true -- hors map = bloquant
    end

    return map[ty][tx] == TILE_WALL or map[ty][tx] == TILE_PROP
end

--------------------------------------------------
-- Raycast DDA (Amanatides & Woo) sur grille
-- Retourne une distance en pixels:
-- - sinon : s'arrête à l'entrée du mur
--------------------------------------------------
function Flashlight:_raycastToWallDDA(level, ox, oy, angle, maxDist)
    local ts = TILE_SIZE
    local dx = math.cos(angle)
    local dy = math.sin(angle)

    -- Évite divisions par zéro
    local invDx = (dx ~= 0) and (1 / dx) or 1e12
    local invDy = (dy ~= 0) and (1 / dy) or 1e12

    -- Position en coord tuiles continues (0-based)
    local gx = ox / ts
    local gy = oy / ts

    -- Tuile courante (0-based)
    local tx = math.floor(gx)
    local ty = math.floor(gy)

    -- Sens
    local stepX = (dx >= 0) and 1 or -1
    local stepY = (dy >= 0) and 1 or -1

    -- Prochaine frontière
    local nextGridX = (stepX == 1) and (tx + 1) or tx
    local nextGridY = (stepY == 1) and (ty + 1) or ty

    -- tMax: distance jusqu'à la prochaine frontière en x/y
    local tMaxX = (nextGridX - gx) * ts * invDx
    local tMaxY = (nextGridY - gy) * ts * invDy

    -- tDelta: distance pour traverser 1 tuile
    local tDeltaX = ts * math.abs(invDx)
    local tDeltaY = ts * math.abs(invDy)

    local tPrev = 0
    local eps = self.rayEpsilon or 1.0

    while tPrev <= maxDist do
        local tEnter

        -- On entre dans la prochaine tuile
        if tMaxX < tMaxY then
            tx = tx + stepX
            tEnter = tMaxX
            tMaxX = tMaxX + tDeltaX
        else
            ty = ty + stepY
            tEnter = tMaxY
            tMaxY = tMaxY + tDeltaY
        end

        local mapX = tx + 1
        local mapY = ty + 1

        -- Si c'est un mur -> on s'arrête AVANT d'entrer dans la tuile mur
        if self:_isWall(level, mapX, mapY) then
            local hit = math.min(maxDist, tEnter - eps)
            return math.max(0, hit)
        end

        tPrev = tEnter
    end

    return maxDist
end

return Flashlight
