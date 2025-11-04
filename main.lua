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
local simulationPopup = require("simulation_popup")

-- Options and settings
local optionsMenu = require("options_menu")
local SettingsManager = require("settings_manager")
local UIScale = require("ui_scale")

-- Animation and utility libraries
local flux = require("lib.flux")
local lume = require("lib.lume")

-- Game State Management
-- Possible states: "menu", "coach_selection", "team_naming", "season_menu", "game", "simulating", "season_end", "options"
local gameState = "menu"
local previousState = "menu"  -- Track previous state for returning from options
local simulationComplete = false

--- LÖVE Callback: Initialization
--- Called once at game startup. Initializes the window and loads the main menu.
function love.load()
    -- Load and apply saved settings
    local settings = SettingsManager.load()
    SettingsManager.apply(settings)

    -- Initialize UI scaling
    UIScale.update()

    -- Set window title
    love.window.setTitle("The Gridiron Bazaar")

    -- Initialize main menu
    menu.load()
end

--- LÖVE Callback: Update Logic
--- Called every frame. Updates the current game state and handles state transitions.
--- @param dt number Delta time in seconds since last frame
function love.update(dt)
    -- Update animation library
    flux.update(dt)

    -- Menu State
    if gameState == "menu" then
        menu.update(dt)

        -- Transition to coach selection when player clicks "Start New Season"
        if menu.startGameRequested then
            gameState = "coach_selection"
            coachSelection.load()
            menu.startGameRequested = false
        end

        -- Transition to season menu when player clicks "Continue Season"
        if menu.continueSeasonRequested then
            if SeasonManager.loadSeason() then
                gameState = "season_menu"
                seasonMenu.load()
            else
                -- Failed to load - show error or stay in menu
                print("Error: Failed to load season save")
            end
            menu.continueSeasonRequested = false
        end

        -- Transition to options menu
        if menu.optionsRequested then
            previousState = "menu"
            gameState = "options"
            optionsMenu.load("menu")
            menu.optionsRequested = false
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
            -- Reset the flag immediately to prevent match restart loop
            scoutingScreen.startMatchRequested = false

            -- Get match data
            local matchData = SeasonManager.getPlayerMatch()

            if matchData then
                -- Load match with player and opponent info
                gameState = "game"
                match.load(
                    SeasonManager.playerTeam.coachId,
                    matchData.opponentTeam.coachId,
                    SeasonManager.playerTeam.name,
                    matchData.opponentTeam.name
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

        -- Transition to options menu from pause menu
        if match.optionsRequested then
            previousState = "game"
            gameState = "options"
            optionsMenu.load("pause")
            match.optionsRequested = false
        end

        -- Return to season menu when match ends
        if match.shouldReturnToMenu then
            -- Reset flag immediately
            match.shouldReturnToMenu = false

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

                -- Award cash for playing the game
                local playerWon = (matchData.isHome and playerScore > aiScore) or (not matchData.isHome and aiScore > playerScore)
                local cashReward = playerWon and 100 or 50  -- 100 for win, 50 for loss
                SeasonManager.playerTeam:awardCash(cashReward)

                -- Store MVP data
                SeasonManager.lastMatchResult.mvpOffense = match.getMVPOffense()
                SeasonManager.lastMatchResult.mvpDefense = match.getMVPDefense()

                -- Update player team cards with match statistics
                SeasonManager.updatePlayerCardStats(
                    match.getPlayerOffensiveCards(),
                    match.getPlayerDefensiveCards()
                )

                -- Check if player lost in playoffs
                if SeasonManager.inPlayoffs and not playerWon then
                    -- Simulate all remaining playoff games
                    SeasonManager.simulateRemainingPlayoffs()

                    -- Transition directly to season end screen
                    gameState = "season_end"
                    seasonEndScreen.load()
                else
                    -- Transition to simulation state (regular season or playoff win)
                    gameState = "simulating"
                    simulationComplete = false
                    simulationPopup.show()
                end
            end
        end

    -- Simulating AI Games State
    elseif gameState == "simulating" then
        if not simulationComplete then
            -- Run simulation (this happens in one frame)
            SeasonManager.simulateWeek()

            -- Advance to next week
            SeasonManager.nextWeek()

            -- Advance to training phase
            SeasonManager.goToTraining()

            simulationComplete = true

            -- Auto-save after match
            SeasonManager.saveSeason()

            -- Brief delay to show popup (transition in next frame)
            love.timer.sleep(0.5)
        end

        if simulationComplete then
            simulationPopup.hide()
            gameState = "season_menu"
            seasonMenu.load()
        end

    -- Options Menu State
    elseif gameState == "options" then
        optionsMenu.update(dt)

        -- Return to previous state
        if optionsMenu.backRequested then
            optionsMenu.backRequested = false

            -- Reload UI if settings changed
            if optionsMenu.needsReload then
                optionsMenu.needsReload = false

                -- Reload all UI modules to reflect new scaling
                if previousState == "menu" then
                    gameState = "menu"
                    menu.load()
                elseif previousState == "game" then
                    gameState = "game"
                    -- No need to reload match, just update UI scale
                    UIScale.update()
                end
            else
                gameState = previousState
            end
        end

    -- Season End State
    elseif gameState == "season_end" then
        seasonEndScreen.update(dt)

        -- Return to menu
        if seasonEndScreen.isReturnToMenuRequested() then
            -- Delete save file when season ends
            SeasonManager.deleteSave()

            gameState = "menu"
            menu.load()

        -- Start new season
        elseif seasonEndScreen.isNewSeasonRequested() then
            -- Delete save file when starting new season
            SeasonManager.deleteSave()

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
    elseif gameState == "simulating" then
        -- Draw the match screen in background, then overlay popup
        match.draw()
        simulationPopup.draw()
    elseif gameState == "options" then
        optionsMenu.draw()
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
        seasonMenu.keypressed(key)
    elseif gameState == "game" then
        match.keypressed(key)
    elseif gameState == "options" then
        optionsMenu.keypressed(key)
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
    elseif gameState == "options" then
        optionsMenu.mousepressed(x, y, button)
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
    elseif gameState == "season_menu" then
        seasonMenu.mousemoved(x, y)
    elseif gameState == "game" then
        match.mousemoved(x, y)
    elseif gameState == "options" then
        optionsMenu.mousemoved(x, y)
    end
end

--- LÖVE Callback: Mouse Released
--- Handles mouse button release events. Delegates to current state module.
--- @param x number Mouse X position in pixels
--- @param y number Mouse Y position in pixels
--- @param button number Mouse button (1=left, 2=right, 3=middle)
function love.mousereleased(x, y, button)
    if gameState == "season_menu" then
        seasonMenu.mousereleased(x, y, button)
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
        seasonMenu.wheelmoved(x, y)
    end
end
