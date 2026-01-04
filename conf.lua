function love.conf(t)
    -- CONFIG GLOBALE DU JEU (accessibles partout)
    TILE_SIZE    = 32
    W_MAX_WIDTH  = 1280
    W_MAX_HEIGHT = 720

    DEBUG_CURRENT_SEED   = "NONE"
    DEBUG_CURRENT_LEVEL  = 1
    DEBUG_MODE           = false
    FLASHLIGHT_DISABLED  = true
    FREEZE               = false

    -- Code tiles
    TILE_EMPTY = 0
    TILE_FLOOR = 1
    TILE_WALL = 2
    TILE_PROP = 3
    TILE_GLASS = 4
    TILE_CORRIDOR = 5


    t.window.title = "Latente Fear"
    t.window.width = W_MAX_WIDTH
    t.window.height = W_MAX_HEIGHT
    t.window.vsync = 1         -- Évite les déchirements d'image
    t.console = true           -- Très important pour voir tes erreurs et tes prints
end