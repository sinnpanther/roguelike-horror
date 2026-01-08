local Room = require "src.map.Room"
local RuinWall = require "src.map.props.RuinWall"

local GraveyardLayout = Class:extend()

function GraveyardLayout:new(level, profile, seed)
    self.level = level
    self.world = level.world
    self.profile = profile
    self.rng = love.math.newRandomGenerator(seed)
    self.map = level.map
end

--------------------------------------------------
-- ENTRY POINT
--------------------------------------------------
function GraveyardLayout:build()
    self:_createRoom()
    self:_placeRuins()
end

--------------------------------------------------
-- MAIN ROOM (unique, organique)
--------------------------------------------------
function GraveyardLayout:_createRoom()
    local profile = self.profile

    -- Taille de base (profil)
    local w = self.rng:random(profile.roomWidth.min, profile.roomWidth.max)
    local h = self.rng:random(profile.roomHeight.min, profile.roomHeight.max)

    -- Centrage
    local x = math.floor((self.level.mapW - w) / 2)
    local y = math.floor((self.level.mapH - h) / 2)

    local rect = {
        x = x,
        y = y,
        w = w,
        h = h
    }

    -- Room logique (spawn, ennemis, etc.)
    local roomSeed = self.rng:random(1, 2^30)
    local room = Room(self.level.world, self.level, roomSeed, self.profile, rect)
    table.insert(self.level.rooms, room)

    -- Carving organique
    room:carve(profile)
end

function GraveyardLayout:_placeRuins()
    local level = self.level

    level.props = level.props or {}

    local margin = 2

    for y = margin, level.mapH - margin do
        for x = margin, level.mapW - margin do

            if level.map[y][x] == TILE_PROP then
                table.insert(level.props, RuinWall(level.world, x, y, { theme = self.level.theme }))
            end
        end
    end
end

return GraveyardLayout