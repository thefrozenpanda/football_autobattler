--- main.lua
--- Main Entry Point and Game State Manager
---
--- This file serves as the primary entry point for The Gridiron Bazaar.
--- It manages the game state machine, routing between menu, coach selection,
--- team naming, season menu, match gameplay, and season end screens.
--- All LÖVE callbacks are implemented here and delegated to the appropriate
--- module based on current game state.
---
--- Dependencies:
---   - match.lua: Match gameplay logic
---   - menu.lua: Main menu interface
---   - coach_selection.lua: Coach selection screen
---   - coach.lua: Coach data and definitions
---   - team_naming.lua: Team naming screen for Season Mode
---   - season_menu.lua: Season Mode central hub
---   - season_end_screen.lua: End of season results
---   - season_manager.lua: Season state management
---   - training_screen.lua, lineup_screen.lua, schedule_screen.lua,
---     stats_screen.lua, scouting_screen.lua: Season Mode sub-screens
---
--- Used by: LÖVE2D engine
--- LÖVE Callbacks: love.load, love.update, love.draw, love.keypressed,
---                 love.mousepressed, love.mousemoved, love.textinput,
---                 love.wheelmoved

-- Module Dependencies
local match = require("match")
local menu = require("menu")
local coachSelection = require("coach_selection")
local Coach = require("coach")

-- Season Mode modules
local teamNaming = require("team_naming")
local seasonMenu = require("season_menu")
local seasonEndScreen = require("season_end_screen")
local SeasonManager = require("season_manager")

-- Game State Management
-- Possible states: "menu", "coach_selection", "team_naming", "season_menu", "game", "season_end"
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

        -- Transition to team naming when coach is selected (Season Mode)
        if coachSelection.coachSelected then
            local playerCoachId = coachSelection.selectedCoachId

            gameState = "team_naming"
            teamNaming.load(Coach.getById(playerCoachId))
            coachSelection.coachSelected = false

        -- Return to menu if player cancels (ESC key)
        elseif coachSelection.cancelSelection then
            gameState = "menu"
            menu.load()
            coachSelection.cancelSelection = false
        end

    -- Team Naming State (Season Mode)
    elseif gameState == "team_naming" then
        teamNaming.update(dt)

        -- Transition to season menu when team name confirmed
        if teamNaming.isConfirmed() then
            local playerCoachId = coachSelection.selectedCoachId
            local teamName = teamNaming.getTeamName()

            -- Start new season
            SeasonManager.startNewSeason(playerCoachId, teamName)

            gameState = "season_menu"
            seasonMenu.load()
        end

    -- Season Menu State (Season Mode Hub)
    elseif gameState == "season_menu" then
        seasonMenu.update(dt)

        -- Check if player clicked "Start Match" from scouting screen
        local scoutingScreen = require("scouting_screen")
        if scoutingScreen.isStartMatchRequested() then
            -- Get match data
            local matchData = SeasonManager.getPlayerMatch()

            if matchData then
                -- Load match with player and opponent coach IDs
                gameState = "game"
                match.load(
                    SeasonManager.playerTeam.coachId,
                    matchData.opponentTeam.coachId
                )

                -- Advance to match phase
                SeasonManager.goToMatch()
            end

        -- Check if season is complete
        elseif SeasonManager.isSeasonComplete() then
            gameState = "season_end"
            seasonEndScreen.load()

        -- Check if player wants to quit
        elseif seasonMenu.isQuitRequested() then
            gameState = "menu"
            menu.load()

        -- Check if player wants to save
        elseif seasonMenu.isSaveRequested() then
            -- TODO: Implement save functionality
            -- For now, just acknowledge the request
            seasonMenu.saveRequested = false
        end

    -- Match Gameplay State
    elseif gameState == "game" then
        match.update(dt)

        -- Return to season menu when match ends
        if match.shouldReturnToMenu then
            -- Record match result
            local matchData = SeasonManager.getPlayerMatch()
            if matchData then
                local playerScore = match.getPlayerScore()
                local aiScore = match.getAIScore()

                SeasonManager.recordMatchResult(
                    matchData.isHome and SeasonManager.playerTeam or matchData.opponentTeam,
                    matchData.isHome and matchData.opponentTeam or SeasonManager.playerTeam,
                    matchData.isHome and playerScore or aiScore,
                    matchData.isHome and aiScore or playerScore
                )

                -- Store MVP data
                SeasonManager.lastMatchResult.mvpOffense = match.getMVPOffense()
                SeasonManager.lastMatchResult.mvpDefense = match.getMVPDefense()

                -- Simulate remaining games in the week
                SeasonManager.simulateWeek()

                -- Advance to training phase
                SeasonManager.goToTraining()
            end

            gameState = "season_menu"
            seasonMenu.load()
            match.shouldReturnToMenu = false
        end

    -- Season End State
    elseif gameState == "season_end" then
        seasonEndScreen.update(dt)

        -- Return to menu
        if seasonEndScreen.isReturnToMenuRequested() then
            gameState = "menu"
            menu.load()

        -- Start new season
        elseif seasonEndScreen.isNewSeasonRequested() then
            gameState = "coach_selection"
            coachSelection.load()
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
    elseif gameState == "team_naming" then
        teamNaming.draw()
    elseif gameState == "season_menu" then
        seasonMenu.draw()
    elseif gameState == "game" then
        match.draw()
    elseif gameState == "season_end" then
        seasonEndScreen.draw()
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
    elseif gameState == "team_naming" then
        teamNaming.keypressed(key)
    elseif gameState == "season_menu" then
        -- Season menu doesn't need keypressed
    elseif gameState == "game" then
        match.keypressed(key)
    elseif gameState == "season_end" then
        -- Season end doesn't need keypressed
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
    elseif gameState == "team_naming" then
        teamNaming.mousepressed(x, y, button)
    elseif gameState == "season_menu" then
        seasonMenu.mousepressed(x, y, button)
    elseif gameState == "game" then
        match.mousepressed(x, y, button)
    elseif gameState == "season_end" then
        seasonEndScreen.mousepressed(x, y, button)
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

--- LÖVE Callback: Text Input
--- Handles text input events (for team naming screen)
--- @param text string The UTF-8 encoded text input
function love.textinput(text)
    if gameState == "team_naming" then
        teamNaming.textinput(text)
    end
end

--- LÖVE Callback: Mouse Wheel Movement
--- Handles mouse wheel scrolling events
--- @param x number Horizontal scroll amount
--- @param y number Vertical scroll amount
function love.wheelmoved(x, y)
    if gameState == "season_menu" then
        -- Forward to season menu which will delegate to current screen
        local currentScreen = seasonMenu.currentScreen
        if currentScreen == "schedule" then
            local scheduleScreen = require("schedule_screen")
            scheduleScreen.wheelmoved(y)
        elseif currentScreen == "stats" then
            local statsScreen = require("stats_screen")
            statsScreen.wheelmoved(y)
        end
    end
end
