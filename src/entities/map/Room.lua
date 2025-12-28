local Room = Class:extend()

function Room:new(world, rng, levelIndex, rect)
    self.world = world
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

function Room:centerX()
    local cx = self.rect.x + self.rect.w / 2
    return cx
end

function Room:spawnEnemies()
    local Chaser = require "src.entities.enemies.Chaser"

    local maxPerRoom = 4
    local enemyCount = math.min(1 + math.floor(self.levelIndex / 2), maxPerRoom)

    for i = 1, enemyCount do
        local gx = self.rng:random(self.rect.x + 2, self.rect.x + self.rect.w - 3)
        local gy = self.rng:random(self.rect.y + 2, self.rect.y + self.rect.h - 3)
        local ex = (gx - 1) * self.ts
        local ey = (gy - 1) * self.ts
        table.insert(self.enemies, Chaser(self.world, ex, ey))
    end
end

function Room:drawContents()
    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end
end

return Room
