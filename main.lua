-- Global libs
Class = require "src.libs.classic"
Bump = require "src.libs.bump"
GameState = require "src.libs.hump.gamestate"

-- State files
local Menu = require "src.states.menu"

function love.load()
    -- Register basic callbacks (update, draw, etc.)
    GameState.registerEvents()
    love.graphics.setDefaultFilter("nearest", "nearest")
    -- Run Menu
    GameState.switch(Menu)
end