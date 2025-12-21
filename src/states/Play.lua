-- Requirements
local Camera = require "libs.hump.camera"

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
    self.player = Player(self.room.x + self.room.width/2, self.room.y + self.room.height/2)
    self.world:add(self.player, self.player.x, self.player.y, self.player.w, self.player.h)

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

    -- 1. NETTOYAGE TOTAL (Murs, Portes, futurs Ennemis...)
    WorldUtils.clearWorld(self.world)

    -- 2. GÉNÉRATION
    self.level = self.level + 1
    self.room = Room(self.world, self.numericSeed, self.level)
    self.room:generate(entrySide)

    -- Repositionnement du joueur à l'OPPOSÉ
    local margin = 60
    if exitSide == "north" then -- Sorti par le haut -> Arrive par le bas
        self.player.x, self.player.y = self.room.x + self.room.width/2, self.room.y + self.room.height - margin
    elseif exitSide == "south" then -- Sorti par le bas -> Arrive par le haut
        self.player.x, self.player.y = self.room.x + self.room.width/2, self.room.y + margin
    elseif exitSide == "west" then -- Sorti par la gauche -> Arrive par la droite
        self.player.x, self.player.y = self.room.x + self.room.width - margin, self.room.y + self.room.height/2
    elseif exitSide == "east" then -- Sorti par la droite -> Arrive par la gauche
        self.player.x, self.player.y = self.room.x + margin, self.room.y + self.room.height/2
    end

    self.player.hasReachedExit = false -- Très important pour ne pas boucler !
    self.world:update(self.player, self.player.x, self.player.y)
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