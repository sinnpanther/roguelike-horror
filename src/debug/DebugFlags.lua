local DebugFlags = {
    enabled = false,

    player = {
        enabled = false,
        fov = false,
        state = false,
        hitbox = false,
        direction = false,
        range = false,
    },

    enemy = {
        enabled = false,
        fov = false,
        direction = false,
        range = false,
        state = false,
        hitbox = false,
    },

    play = {
        enabled = false,
        world = false,
    },

    spatialHash = {
        enabled = false,
    },

    hud = {
        enabled = false,
    },

    level = {
        rooms = false,
        corridors = false,
        tiles = false,
    },

    puzzles = {
        enabled = false,
        targets = false,
    }
}

return DebugFlags
