local Suit = require "libs.suit"
local DebugFlags = require "src.debug.DebugFlags"

local DebugState = {}

--------------------------------------------------
-- STATE LIFECYCLE
--------------------------------------------------
function DebugState:enter()
    self.w = love.graphics.getWidth()
    self.h = love.graphics.getHeight()

    self.colWidth = 260
    self.rowHeight = 26

    self.leftX = self.w * 0.1
    self.rightX = self.w * 0.55
    self.startY = self.h * 0.15

    --------------------------------------------------
    -- UI STATE (PERSISTENT OBJECTS)
    --------------------------------------------------
    self.ui = {
        enabled = {checked = DebugFlags.enabled, text = " Debug enabled"},

        player = {
            enabled = {checked = DebugFlags.player.enabled, text = " enabled"},
            fov = {checked = DebugFlags.player.fov, text = " fov"},
            state = {checked = DebugFlags.player.state, text = " state"},
            hitbox = {checked = DebugFlags.player.hitbox, text = " hitbox"},
            direction = {checked = DebugFlags.player.direction, text = " direction"},
            range = {checked = DebugFlags.player.range, text = " range"},
        },

        enemy = {
            enabled = {checked = DebugFlags.enemy.enabled, text = " enabled"},
            fov = {checked = DebugFlags.enemy.fov, text = " fov"},
            direction = {checked = DebugFlags.enemy.direction, text = " direction"},
            range = {checked = DebugFlags.enemy.range, text = " range"},
            state = {checked = DebugFlags.enemy.state, text = " state"},
            hitbox = {checked = DebugFlags.enemy.hitbox, text = " hitbox"},
        },

        play = {
            enabled = {checked = DebugFlags.play.enabled, text = " enabled"},
            world = {checked = DebugFlags.play.world, text = " world"},
        },

        spatialHash = {
            enabled = {checked = DebugFlags.spatialHash.enabled, text = " enabled"},
        },

        hud = {
            enabled = {checked = DebugFlags.hud.enabled, text = " enabled"},
        },

        level = {
            rooms = {checked = DebugFlags.level.rooms, text = " rooms"},
            corridors = {checked = DebugFlags.level.corridors, text = " corridors"},
            tiles = {checked = DebugFlags.level.tiles, text = " tiles"},
        },

        puzzles = {
            enabled = {checked = DebugFlags.puzzles.enabled, text = " enabled"},
            targets = {checked = DebugFlags.puzzles.targets, text = " targets"},
        }
    }
end

--------------------------------------------------
-- UPDATE
--------------------------------------------------
function DebugState:update(dt)
    Suit.layout:reset(self.leftX, self.startY)
    Suit.layout:padding(6)
    local options = {align = "left"}

    Suit.Label("DEBUG MODE", options, Suit.layout:row(self.colWidth, 32))

    --------------------------------------------------
    -- GLOBAL ENABLE
    --------------------------------------------------
    Suit.Checkbox(self.ui.enabled, Suit.layout:row(self.colWidth, self.rowHeight))
    DebugFlags.enabled = self.ui.enabled.checked

    if Suit.Button("Tout cocher", Suit.layout:row(120, self.rowHeight)).hit then
        self:_applyGlobal(true)
    end

    Suit.layout:push(Suit.layout:col(5, 1))

    if Suit.Button("Tout décocher", Suit.layout:row(120, self.rowHeight)).hit then
        self:_applyGlobal(false)
    end

    Suit.layout:pop()

    --------------------------------------------------
    -- PLAYER
    --------------------------------------------------
    Suit.Label("PLAYER", options, Suit.layout:row(self.colWidth, self.rowHeight))

    for k, checkbox in pairs(self.ui.player) do
        Suit.Checkbox(checkbox, Suit.layout:row(self.colWidth, self.rowHeight))
        DebugFlags.player[k] = checkbox.checked
    end

    --------------------------------------------------
    -- ENEMY
    --------------------------------------------------
    Suit.Label("ENEMY", options, Suit.layout:row(self.colWidth, self.rowHeight))

    for k, checkbox in pairs(self.ui.enemy) do
        Suit.Checkbox(checkbox, Suit.layout:row(self.colWidth, self.rowHeight))
        DebugFlags.enemy[k] = checkbox.checked
    end

    --------------------------------------------------
    -- RIGHT COLUMN
    --------------------------------------------------
    Suit.layout:reset(self.rightX, self.startY)
    Suit.layout:padding(6)

    Suit.Label("PLAY", options, Suit.layout:row(self.colWidth, self.rowHeight))
    for k, checkbox in pairs(self.ui.play) do
        Suit.Checkbox(checkbox, Suit.layout:row(self.colWidth, self.rowHeight))
        DebugFlags.play[k] = checkbox.checked
    end

    Suit.Label("SPATIAL HASH", options, Suit.layout:row(self.colWidth, self.rowHeight))
    for k, checkbox in pairs(self.ui.spatialHash) do
        Suit.Checkbox(checkbox, Suit.layout:row(self.colWidth, self.rowHeight))
        DebugFlags.spatialHash[k] = checkbox.checked
    end

    Suit.Label("HUD", options, Suit.layout:row(self.colWidth, self.rowHeight))
    for k, checkbox in pairs(self.ui.hud) do
        Suit.Checkbox(checkbox, Suit.layout:row(self.colWidth, self.rowHeight))
        DebugFlags.hud[k] = checkbox.checked
    end

    Suit.Label("LEVEL", options, Suit.layout:row(self.colWidth, self.rowHeight))
    for k, checkbox in pairs(self.ui.level) do
        Suit.Checkbox(checkbox, Suit.layout:row(self.colWidth, self.rowHeight))
        DebugFlags.level[k] = checkbox.checked
    end

    Suit.Label("PUZZLES", options, Suit.layout:row(self.colWidth, self.rowHeight))
    for k, checkbox in pairs(self.ui.puzzles) do
        Suit.Checkbox(checkbox, Suit.layout:row(self.colWidth, self.rowHeight))
        DebugFlags.puzzles[k] = checkbox.checked
    end
end

--------------------------------------------------
-- DRAW
--------------------------------------------------
function DebugState:draw()
    love.graphics.clear(0.05, 0.05, 0.05)
    Suit.draw()
end

--------------------------------------------------
-- APPLY GLOBAL STATE
--------------------------------------------------
function DebugState:_applyGlobal(value)
    -- Global
    self.ui.enabled.checked = value
    DebugFlags.enabled = value

    -- Parcours de toutes les sections
    for sectionName, section in pairs(self.ui) do
        if type(section) == "table" then
            for key, checkbox in pairs(section) do
                if type(checkbox) == "table" and checkbox.checked ~= nil then
                    checkbox.checked = value
                end
            end
        end
    end

    -- Synchronisation vers DebugFlags
    for sectionName, section in pairs(DebugFlags) do
        if type(section) == "table" then
            for key, _ in pairs(section) do
                if type(section[key]) == "boolean" then
                    section[key] = value
                end
            end
        elseif type(DebugFlags[sectionName]) == "boolean" then
            DebugFlags[sectionName] = value
        end
    end
end

--------------------------------------------------
-- INPUT
--------------------------------------------------
function DebugState:keypressed(key)
    if key == "f1" then
        return GameState.pop()
    end
end

return DebugState
