local Room = Class:extend()

function Room:new(world, level, rng, levelIndex, rect)
    self.world = world
    self.level = level
    self.rng = rng
    self.levelIndex = levelIndex
    self.rect = rect
    self.ts = TILE_SIZE

    self.enemies = {}
end

function Room:centerTile()
    local cx = math.floor(self.rect.x + self.rect.w / 2)
    local cy = math.floor(self.rect.y + self.rect.h / 2)

    return cx, cy
end

function Room:containsPoint(x, y)
    return  x >= self.rect.x and
            x <= self.rect.x + self.rect.w and
            y >= self.rect.y and
            y <= self.rect.y + self.rect.h
end

function Room:centerX()
    local cx = self.rect.x + self.rect.w / 2
    return cx
end

function Room:spawnEnemies()
    local Chaser = require "src.entities.enemies.Chaser"
    local Watcher = require "src.entities.enemies.Watcher"

    local maxPerRoom = 4
    local enemyCount = math.min(1 + math.floor(self.levelIndex / 2), maxPerRoom)

    for i = 1, enemyCount do
        local gx = self.rng:random(self.rect.x + 2, self.rect.x + self.rect.w - 3)
        local gy = self.rng:random(self.rect.y + 2, self.rect.y + self.rect.h - 3)
        local ex = (gx - 1) * self.ts
        local ey = (gy - 1) * self.ts

        local enemy
        if self.rng:random() < 0.5 then
            enemy = Chaser(self.world, self.level, ex, ey)
        else
            enemy = Watcher(self.world, self.level, ex, ey)
        end
        self.level.spatialHash:add(enemy)

        table.insert(self.enemies, enemy)
    end
end

return Room
