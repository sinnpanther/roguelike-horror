-- src/states/menu.lua
local Menu = {}

function Menu:draw()
    love.graphics.print("Menu State - Press Enter", 10, 10)
end

function Menu:keypressed(key)
    if key == "return" then
        local Play = require "src.states.Play"
        GameState.switch(Play)
    end
end

return Menu