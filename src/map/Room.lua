local MapUtils = require "src.utils.map_utils"

local Room = Class:extend()

function Room:new(world, level, seed, levelIndex, rect)
    self.world = world
    self.level = level
    self.rng = love.math.newRandomGenerator(seed)
    self.levelIndex = levelIndex
    self.rect = rect
    self.ts = TILE_SIZE

    self.enemies = {}
    self.props = {}
    self.theme = level.theme
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

        -- ✅ uniquement du SOL
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
        if self.rng:random() < 0.5 then
            enemy = Chaser(self.world, self.level, enemySeed, ex, ey)
        else
            enemy = Watcher(self.world, self.level, enemySeed, ex, ey)
        end
        self.level.spatialHash:add(enemy)

        table.insert(self.enemies, enemy)
    end
end

--------
-- PROPS
--------

function Room:_canPlacePillar(tx, ty)
    local map = self.level.map

    -- doit être du sol
    if map[ty][tx] ~= TILE_FLOOR then
        return false
    end

    -- pas collé à un mur
    if map[ty-1][tx] == TILE_WALL or map[ty+1][tx] == TILE_WALL
            or map[ty][tx-1] == TILE_WALL or map[ty][tx+1] == TILE_WALL then
        return false
    end

    return true
end

function Room:spawnPillarsFromMap()
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
