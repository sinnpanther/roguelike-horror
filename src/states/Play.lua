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
end

function Play:update(dt)
    -- Update player logic (movement + collisions)
    self.player:update(dt, self.world)

    -- Update des ennemis
    for _, enemy in ipairs(self.room.enemies) do
        enemy:update(dt, self.player) -- On leur donne accès au joueur pour l'IA
    end

    local targetX = self.player.x + self.player.w / 2
    local targetY = self.player.y + self.player.h / 2
    self.cam:lookAt(targetX, targetY)

    if self.player.hasReachedExit then
        self:nextLevel()

        self.player.hasReachedExit = false
    end
end

function Play:draw()
    -- 1. Tout ce qui est DANS le monde (Camera)
    self.cam:attach()

    self.room:draw()
    self.player:draw()

    self.cam:detach()

    -- Le HUD affiche les infos du niveau actuel
    self.hud:draw(self.level, self.seed)

    -- DEBUG : affiche les hitboxes
    --for _, item in ipairs(self.world:getItems()) do
    --    local x, y, w, h = self.world:getRect(item)
    --    love.graphics.setColor(1, 0, 0, 0.5) -- Rouge transparent
    --    love.graphics.rectangle("line", x, y, w, h)
    --end
    --love.graphics.setColor(1, 1, 1)
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
    -- 1. Check if the pressed key is 'r'
    if key == "r" then
        -- 2. Tell GameState to switch to 'Play' again
        -- This will call Play:enter() and reset everything
        GameState.switch(Play)
    end

    -- 2. Next level
    if key == "n" then
        self:nextLevel()
    end

    -- 3. Return to menu if Escape is pressed
    if key == "tab" then
        local Menu = require "src.states.Menu"
        GameState.switch(Menu)
    end
end

return Play