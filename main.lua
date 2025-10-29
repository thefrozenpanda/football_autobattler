--- main.lua
--- Main Entry Point and Game State Manager
---
--- This file serves as the primary entry point for The Gridiron Bazaar.
--- It manages the game state machine, routing between menu, coach selection,
--- and the actual match gameplay. All LÖVE callbacks are implemented here
--- and delegated to the appropriate module based on current game state.
---
--- Dependencies:
---   - match.lua: Match gameplay logic
---   - menu.lua: Main menu interface
---   - coach_selection.lua: Coach selection screen
---   - coach.lua: Coach data and definitions
---
--- Used by: LÖVE2D engine
--- LÖVE Callbacks: love.load, love.update, love.draw, love.keypressed,
---                 love.mousepressed, love.mousemoved

-- Module Dependencies
local match = require("match")
local menu = require("menu")
local coachSelection = require("coach_selection")
local Coach = require("coach")

-- Game State Management
-- Possible states: "menu", "coach_selection", "game"
local gameState = "menu"

--- LÖVE Callback: Initialization
--- Called once at game startup. Initializes the window and loads the main menu.
function love.load()
    -- Set window properties (NOTE: Duplicates conf.lua settings, but ensures correct state)
    love.window.setTitle("The Gridiron Bazaar")
    love.window.setMode(1600, 900, {resizable=false})

    -- Initialize main menu
    menu.load()
end

--- LÖVE Callback: Update Logic
--- Called every frame. Updates the current game state and handles state transitions.
--- @param dt number Delta time in seconds since last frame
function love.update(dt)
    -- Menu State
    if gameState == "menu" then
        menu.update(dt)

        -- Transition to coach selection when player clicks "Start Game"
        if menu.startGameRequested then
            gameState = "coach_selection"
            coachSelection.load()
            menu.startGameRequested = false
        end

    -- Coach Selection State
    elseif gameState == "coach_selection" then
        coachSelection.update(dt)

        -- Transition to match when coach is selected
        if coachSelection.coachSelected then
            local playerCoachId = coachSelection.selectedCoachId
            local aiCoach = Coach.getRandom()  -- AI gets random coach

            gameState = "game"
            match.load(playerCoachId, aiCoach.id)
            coachSelection.coachSelected = false

        -- Return to menu if player cancels (ESC key)
        elseif coachSelection.cancelSelection then
            gameState = "menu"
            menu.load()
            coachSelection.cancelSelection = false
        end

    -- Match Gameplay State
    elseif gameState == "game" then
        match.update(dt)

        -- Return to menu when match ends and player clicks "Return to Menu"
        if match.shouldReturnToMenu then
            gameState = "menu"
            menu.load()
            match.shouldReturnToMenu = false
        end
    end
end

--- LÖVE Callback: Rendering
--- Called every frame. Delegates drawing to the appropriate module based on game state.
function love.draw()
    if gameState == "menu" then
        menu.draw()
    elseif gameState == "coach_selection" then
        coachSelection.draw()
    elseif gameState == "game" then
        match.draw()
    end
end

--- LÖVE Callback: Keyboard Input
--- Handles keyboard key press events. Delegates to current state module.
--- @param key string The key that was pressed
function love.keypressed(key)
    if gameState == "menu" then
        menu.keypressed(key)
    elseif gameState == "coach_selection" then
        coachSelection.keypressed(key)
    elseif gameState == "game" then
        match.keypressed(key)
    end
end

--- LÖVE Callback: Mouse Button Input
--- Handles mouse button press events. Delegates to current state module.
--- @param x number Mouse X position in pixels
--- @param y number Mouse Y position in pixels
--- @param button number Mouse button (1=left, 2=right, 3=middle)
function love.mousepressed(x, y, button)
    if gameState == "menu" then
        menu.mousepressed(x, y, button)
    elseif gameState == "coach_selection" then
        coachSelection.mousepressed(x, y, button)
    elseif gameState == "game" then
        match.mousepressed(x, y, button)
    end
end

--- LÖVE Callback: Mouse Movement
--- Handles mouse movement events. Delegates to current state module.
--- Used for button hover effects and UI feedback.
--- @param x number Current mouse X position in pixels
--- @param y number Current mouse Y position in pixels
--- @param dx number Change in X position since last frame
--- @param dy number Change in Y position since last frame
function love.mousemoved(x, y, dx, dy)
    if gameState == "menu" then
        menu.mousemoved(x, y)
    elseif gameState == "coach_selection" then
        coachSelection.mousemoved(x, y)
    elseif gameState == "game" then
        match.mousemoved(x, y)
    end
end
