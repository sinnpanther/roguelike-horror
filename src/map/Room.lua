local MapUtils = require "src.utils.map_utils"

local Room = Class:extend()

function Room:new(world, level, seed, profile, rect)
    self.world = world
    self.level = level
    self.levelIndex = level.levelIndex
    self.rng = love.math.newRandomGenerator(seed)
    self.rect = rect
    self.ts = TILE_SIZE
    self.profile = profile

    self.enemies = {}
    self.props = {}
    self.theme = level.theme
end

function Room:carve()
    local shape = self.profile.roomShape

    if shape == "rect" then
        self:_carveRect()
    elseif shape == "organic" then
        self:_carveOrganic()
    elseif shape == "blob" then
        self:_carveBlob()
    elseif shape == "single" then
        self:_carveSingle()
    end
end

function Room:_carveRect()
    local map = self.level.map

    for y = self.rect.y, self.rect.y + self.rect.h - 1 do
        for x = self.rect.x, self.rect.x + self.rect.w - 1 do
            map[y][x] = TILE_FLOOR
        end
    end
end

function Room:getRandomSpawn(player)
    local map = self.level.map
    local ts = TILE_SIZE

    local maxAttempts = 50

    for i = 1, maxAttempts do
        local tx = self.rng:random(
                self.rect.x + 1,
                self.rect.x + self.rect.w - 2
        )
        local ty = self.rng:random(
                self.rect.y + 1,
                self.rect.y + self.rect.h - 2
        )

        -- Uniquement du SOL
        if map[ty] and MapUtils:isWalkableTile(map, tx, ty) then
            local px = (tx - 1) * ts
            local py = (ty - 1) * ts

            -- centrage du player si nécessaire
            if player and player.w and player.h then
                px = px - player.w / 2
                py = py - player.h / 2
            end

            return px, py
        end
    end

    -- fallback ultime (ne devrait jamais arriver)
    return (self.rect.x + 1) * ts, (self.rect.y + 1) * ts
end

function Room:centerTile()
    local cx = math.floor(self.rect.x + self.rect.w / 2)
    local cy = math.floor(self.rect.y + self.rect.h / 2)

    return cx, cy
end

function Room:centerX()
    local cx = self.rect.x + self.rect.w / 2
    return cx
end

function Room:_getRandomFloorTile()
    local map = self.level.map

    local maxAttempts = 20
    local attempts = 0

    while attempts < maxAttempts do
        attempts = attempts + 1

        local tx = self.rng:random(self.rect.x + 1, self.rect.x + self.rect.w - 2)
        local ty = self.rng:random(self.rect.y + 1, self.rect.y + self.rect.h - 2)

        -- Uniquement du sol
        if MapUtils:isWalkableTile(map, tx, ty) then
            return tx, ty
        end
    end

    -- Échec : aucune tile valide trouvée
    return nil, nil
end

function Room:spawnEnemies()
    local Chaser = require "src.entities.enemies.Chaser"
    local Watcher = require "src.entities.enemies.Watcher"

    local maxPerRoom = 4
    local enemyCount = math.min(1 + math.floor(self.levelIndex / 2), maxPerRoom)

    for i = 1, enemyCount do
        local tx, ty = self:_getRandomFloorTile()

        -- sécurité : si aucune tile valide, on skip
        if not tx then
            break
        end

        local ex = (tx - 1) * self.ts
        local ey = (ty - 1) * self.ts

        local enemy
        local enemySeed = self.rng:random(1, 2^30)
        if self.rng:random() < self.profile.enemyChance then
            enemy = Chaser(self.world, self.level, enemySeed, ex, ey)
        else
            enemy = Watcher(self.world, self.level, enemySeed, ex, ey)
        end
        self.level.spatialHash:add(enemy)

        table.insert(self.enemies, enemy)
    end
end

--------------------------------
-- Walls
--------------------------------
function Room:buildInternalWalls(profile)
    if self.rng:random() > profile.internalWallChance then
        return
    end

    -- room trop petite
    if self.rect.w < 10 or self.rect.h < 10 then
        return
    end

    -- orientation du mur
    local orientation = self.rng:random(1, 2)
    -- 1 = horizontal, 2 = vertical

    if orientation == 1 then
        self:_buildHorizontalWall()
    else
        self:_buildVerticalWall()
    end
end

function Room:_buildHorizontalWall()
    local map = self.level.map

    local wallThickness = 2
    local wallMargin = 4

    -- Y possible UNIQUEMENT dans la zone safe
    local minY = self.rect.y + wallMargin
    local maxY = self.rect.y + self.rect.h - wallThickness - wallMargin

    if minY >= maxY then
        return
    end

    local y = self.rng:random(minY, maxY)

    -- Le mur part d’un côté mais pas trop loin
    local fromLeft = self.rng:random() < 0.5

    local minX = self.rect.x + wallMargin
    local maxX = self.rect.x + self.rect.w - wallMargin - 1

    local startX, endX

    if fromLeft then
        startX = self.rect.x
        endX   = self.rng:random(
                minX + 2,
                math.floor(self.rect.x + self.rect.w * 0.6)
        )
    else
        startX = self.rng:random(
                math.floor(self.rect.x + self.rect.w * 0.4),
                maxX - 2
        )
        endX = self.rect.x + self.rect.w - 1
    end

    for ty = y, y + wallThickness - 1 do
        for tx = startX, endX do
            -- Interdit devant un couloir
            if map[ty][tx] == TILE_CORRIDOR then
                return
            end
        end
    end

    for ty = y, y + wallThickness - 1 do
        for tx = startX, endX do
            if MapUtils:isWalkableTile(map, tx, ty) then
                map[ty][tx] = TILE_WALL
            end
        end
    end
end

function Room:_buildVerticalWall()
    local map = self.level.map

    local wallThickness = 2
    local wallMargin = 4

    local minX = self.rect.x + wallMargin
    local maxX = self.rect.x + self.rect.w - wallThickness - wallMargin

    if minX >= maxX then
        return
    end

    local x = self.rng:random(minX, maxX)

    local minY = self.rect.y + wallMargin
    local maxY = self.rect.y + self.rect.h - wallMargin - 1

    local fromTop = self.rng:random() < 0.5

    local startY, endY

    if fromTop then
        startY = self.rect.y
        endY   = self.rng:random(
                minY + 2,
                math.floor(self.rect.y + self.rect.h * 0.6)
        )
    else
        startY = self.rng:random(
                math.floor(self.rect.y + self.rect.h * 0.4),
                maxY - 2
        )
        endY = self.rect.y + self.rect.h - 1
    end

    for tx = x, x + wallThickness - 1 do
        for ty = startY, endY do
            if map[ty][tx] == TILE_CORRIDOR then
                return
            end
        end
    end

    for tx = x, x + wallThickness - 1 do
        for ty = startY, endY do
            if MapUtils:isWalkableTile(map, tx, ty) then
                map[ty][tx] = TILE_WALL
            end
        end
    end
end

--------------------------------
-- Props
--------------------------------

-- Pillars
function Room:generatePillars(profile)
    if not profile.hasPillars then
        return
    end

    if self.rng:random() > profile.pillarChance then
        return
    end

    if self.rect.w < 8 or self.rect.h < 8 then
        return
    end

    local margin = 4

    local left   = self.rect.x + margin
    local right  = self.rect.x + self.rect.w - margin - 1
    local top    = self.rect.y + margin
    local bottom = self.rect.y + self.rect.h - margin - 1

    local positions = {
        { left,  top },
        { right, top },
        { left,  bottom },
        { right, bottom },
    }

    for _, p in ipairs(positions) do
        local tx, ty = p[1], p[2]
        if self:_canPlacePillar(tx, ty) then
            self.level.map[ty][tx] = TILE_PROP
        end
    end

    self:_buildPillars()
end

function Room:_canPlacePillar(tx, ty)
    local map = self.level.map

    -- Si ce n'est pas une tile acceptable
    if not MapUtils:isWalkableTile(map, tx, ty) then
        return false
    end

    return true
end

function Room:_buildPillars()
    local Pillar = require "src.map.props.Pillar"

    for y = self.rect.y, self.rect.y + self.rect.h - 1 do
        for x = self.rect.x, self.rect.x + self.rect.w - 1 do
            if self.level.map[y][x] == TILE_PROP then
                table.insert(self.props, Pillar(self.world, x, y, self.theme))
            end
        end
    end
end

return Room
