-- Global libs
Class = require "libs.classic"
Bump  = require "libs.bump"
GameState = require "libs.hump.gamestate"

-- State files
States = {
    Menu = require "src.states.Menu",
    Play = require "src.states.Play",
    Victory = require "src.states.Victory"
}

function love.load()
    -- Register basic callbacks (update, draw, etc.)
    GameState.registerEvents()

    -- Run Menu
    GameState.switch(States.Menu)
end

-- DEBUG
DEBUG_CURRENT_SEED = "NONE"
DEBUG_CURRENT_LEVEL = 1
DEBUG_MODE = false
FLASHLIGHT_ENABLED = false
FREEZE = false

function love.keypressed(key)
    -- Mode debug
    if key == "f1" then
        DEBUG_MODE = not DEBUG_MODE
    end

    -- Lampe torche ON/OFF
    if key == "f2" then
        FLASHLIGHT_ENABLED = not FLASHLIGHT_ENABLED
    end

    -- Freeze / unfreeze IA
    if key == "f3" then
        FREEZE = not FREEZE
    end

    if key == "escape" then
        love.event.quit()
    end
end

-- Gestion des erreurs (ajout du niveau et de la seed)
local function error_printer(msg, layer)
    print((debug.traceback("Error: " .. tostring(msg), 1 + (layer or 1)):gsub("\n[^\n]+$", "")))
end

function love.errorhandler(msg)
    msg = tostring(msg)
    error_printer(msg, 2)

    -- On prépare les infos de debug personnalisées
    local debug_info = string.format(
            "\n\n--- DEBUG DATA ---\nSEED: %s\nLEVEL: %d\n---------------------------",
            DEBUG_CURRENT_SEED, DEBUG_CURRENT_LEVEL
    )

    -- Le message complet qui sera affiché
    local full_error = msg .. debug_info

    if not love.window or not love.graphics or not love.event then
        return
    end

    if not love.window.isOpen() then
        local success, status = pcall(love.window.setMode, 800, 600)
        if not success or not status then return end
    end

    -- Réinitialiser l'état graphique pour l'écran bleu
    if love.mouse then love.mouse.setVisible(true) love.mouse.setGrabbed(false) love.mouse.setRelativeMode(false) end
    if love.joystick then for i,v in ipairs(love.joystick.getJoysticks()) do v:setVibration() end end
    if love.audio then love.audio.stop() end
    love.graphics.setCanvas()
    love.graphics.setShader()
    love.graphics.setStencilTest()
    love.graphics.setColor(1, 1, 1)

    local trace = debug.traceback()
    local isCopied = false

    -- La boucle d'affichage de l'écran d'erreur
    return function()
        love.event.pump()
        for e, a, b, c in love.event.poll() do
            if e == "quit" then return 1 end
            if e == "keypressed" then
                if a == "escape" then return 1 end

                -- GESTION DU CTRL+C
                -- On vérifie si 'c' est pressé pendant que 'ctrl' est maintenu
                local is_ctrl = love.keyboard.isDown("lctrl", "rctrl") or love.keyboard.isDown("lgui", "rgui")
                if a == "c" and is_ctrl then
                    -- On combine le message d'erreur, nos infos de debug et le traceback
                    local copy_text = full_error .. "\n\n" .. trace
                    love.system.setClipboardText(copy_text)
                    isCopied = true
                end
            end
        end

        love.graphics.clear(89/255, 157/255, 220/255) -- Le bleu classique de LÖVE
        love.graphics.printf(full_error, 40, 40, love.graphics.getWidth() - 80)
        love.graphics.printf(trace, 40, 200, love.graphics.getWidth() - 80)

        -- Affichage du statut
        if isCopied then
            love.graphics.setColor(0, 1, 0) -- Vert pour confirmer
            love.graphics.print("COPIED TO CLIPBOARD !", 40, love.graphics.getHeight() - 40)
        else
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.print("Press Ctrl+C to copy error", 40, love.graphics.getHeight() - 40)
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.present()
    end
end