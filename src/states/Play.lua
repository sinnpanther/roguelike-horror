-- Requirements
local Camera = require "libs.hump.camera"
local Vector = require "libs.hump.vector"

local Play = {}
local Player = require "src.entities.Player"
local HUD = require "src.ui.HUD"
--local Item = require "src.entities.items.Item"
local Room = require "src.entities.Room"

-- Utils
local WorldUtils = require "src.utils.world_utils"
local MathUtils = require "src.utils.math_utils"

function Play:enter()
    self.world = Bump.newWorld(64)
    self.screenW = love.graphics.getWidth()
    self.screenH = love.graphics.getHeight()
    self.level = 1

    -- On génère la seed une seule fois
    self.seed = MathUtils.generateBase36Seed(8)
    self.numericSeed = MathUtils.hashString(self.seed)

    DEBUG_CURRENT_SEED = self.seed
    DEBUG_CURRENT_LEVEL = self.level

    -- On crée la première salle
    self.room = Room(self.world, self.numericSeed, self.level)
    self.room:generate()

    -- On place le joueur au milieu de cette salle
    self.player = Player(self.world, self.room.x + self.room.width/2, self.room.y + self.room.height/2)

    -- HUD
    self.hud = HUD(self.player)

    self.cam = Camera(self.player.x, self.player.y)

    self.flashlight = {
        coneAngle = 0.45,  -- demi-angle du cône (en radians)
        innerRadius = 30,  -- petit halo autour du joueur
        outerRadius = 300, -- portée principale
        flickerAmp = 5    -- amplitude max du flicker sur le rayon
    }
    self.flickerTime = 0  -- temps pour le bruit de Perlin
end

function Play:update(dt)
    -- Update player logic (movement + collisions)
    self.player:update(dt)

    -- Update des ennemis
    for _, enemy in ipairs(self.room.enemies) do
        enemy:update(dt, self.player) -- On leur donne accès au joueur pour l'IA
    end

    local pCenter = self.player:getCenter()
    self.cam:lookAt(pCenter.x, pCenter.y)

    -- Flicker plus rapide que le temps réel
    self.flickerTime = self.flickerTime + dt

    if self.player.hasReachedExit then
        self:nextLevel()

        self.player.hasReachedExit = false
    end
end

function Play:draw()
    -- 1. On dessine d'abord le "noir" (bleuté très foncé) sur tout l'écran
    love.graphics.clear(0, 0, 0)

    -- Regard à travers la caméra
    self.cam:attach()

    -- Dessine la pièce
    self.room:draw()
    -- Dessine le joueur
    self.player:draw()

    -- Stop du regard à travers la caméra
    self.cam:detach()

    if not FLASHLIGHT_ENABLED then
        -- Le HUD affiche les infos du niveau actuel
        self.hud:draw(self.level, self.seed)

        if DEBUG_MODE then
            self:debug()
        end

        return
    end

    -- 2. Active la lampe torche
    love.graphics.stencil(function()
        self.cam:attach()

        local pCenter = self.player:getCenter()
        local angle = self.player.angle or 0

        -- --- FLICKER DU RAYON ---
        -- n varie doucement entre 0 et 1
        local n = love.math.noise(self.flickerTime, 0.0)
        -- On le remappe en [-1, 1], puis on multiplie par l’amplitude
        local radiusOffset = (n - 0.5) * 2 * self.flashlight.flickerAmp
        local outerRadius = self.flashlight.outerRadius + radiusOffset

        -- Cône principal de la lampe
        love.graphics.arc(
                "fill",
                pCenter.x, pCenter.y,
                outerRadius,
                angle - self.flashlight.coneAngle,
                angle + self.flashlight.coneAngle,
                48
        )

        -- Petit halo proche du joueur
        love.graphics.circle("fill", pCenter.x, pCenter.y, self.flashlight.innerRadius)

        self.cam:detach()
    end, "replace", 1)

    love.graphics.setStencilTest("equal", 0)

    -- 3. On dessine le voile noir PAR-DESSUS tout,
    -- sauf là où le stencil a marqué "1"
    love.graphics.setStencilTest("less", 1)
    love.graphics.setColor(0, 0, 0.02, 0.98) -- Noir bleuté très sombre
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setStencilTest()

    if DEBUG_MODE then
        self:debug()
    end
end

function Play:nextLevel()
    local exitSide = self.player.lastExitSide
    local opposite = {north="south", south="north", east="west", west="east"}
    local entrySide = opposite[exitSide]

    -- 1. NETTOYAGE (On vide le monde Bump avant de recréer la salle)
    WorldUtils.clearWorld(self.world)

    -- 2. GÉNÉRATION DE LA NOUVELLE SALLE
    self.level = self.level + 1
    self.room = Room(self.world, self.numericSeed, self.level)
    self.room:generate(entrySide)

    -- 3. REPOSITIONNEMENT DU JOUEUR (Opti de pro avec HUMP Vector)
    local margin = 60
    local centerX = self.room.x + self.room.width / 2
    local centerY = self.room.y + self.room.height / 2

    -- Calcul des distances max depuis le centre
    local offsetW = (self.room.width / 2) - margin
    local offsetH = (self.room.height / 2) - margin

    -- On crée un nouveau vecteur position basé sur le centre
    local newPos = Vector(centerX, centerY)

    if exitSide == "north" then     -- Sorti par le haut -> Arrive en bas
        newPos.y = newPos.y + offsetH
    elseif exitSide == "south" then -- Sorti par le bas -> Arrive en haut
        newPos.y = newPos.y - offsetH
    elseif exitSide == "west" then  -- Sorti par la gauche -> Arrive à droite
        newPos.x = newPos.x + offsetW
    elseif exitSide == "east" then  -- Sorti par la droite -> Arrive à gauche
        newPos.x = newPos.x - offsetW
    end

    -- 4. SYNCHRONISATION TOTALE
    MathUtils.updateCoordinates(self.player, newPos.x, newPos.y)

    -- On téléporte physiquement le joueur dans le monde Bump (sans collision)
    self.world:update(self.player, self.player.x, self.player.y)

    -- 5. RESET DES ÉTATS
    self.player.hasReachedExit = false
end

function Play:keypressed(key)
    -- Reload
    if key == "r" then
        GameState.switch(Play)
    end

    -- Next level
    if key == "n" then
        self:nextLevel()
    end

    -- Return to menu
    if key == "tab" then
        local Menu = require "src.states.Menu"
        GameState.switch(Menu)
    end
end

-- --- SECTION DEBUG GLOBALE ---
function Play:debug()
    love.graphics.setColor(0, 1, 1, 0.5) -- Cyan transparent

    -- On récupère tous les objets enregistrés dans Bump
    local items, len = self.world:getItems()
    for i = 1, len do
        local x, y, w, h = self.world:getRect(items[i])
        love.graphics.rectangle("line", x, y, w, h)
        -- On écrit le type d'objet à côté pour être sûr
        love.graphics.print(items[i].type or "unknown", x, y - 15)
    end

    -- Petit texte d'info en haut à gauche
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("DEBUG MODE - FPS: "..love.timer.getFPS(), 10, 10, self.screenW - 20, "right")
end

return Play