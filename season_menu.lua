--- season_menu.lua
--- Season Menu - Central Hub
---
--- Main hub for Season Mode with bottom navigation bar.
--- Navigation options: [Training] [Lineup] [Schedule] [Stats] [Next Game]
--- Also displays current week, record, and cash.
---
--- Dependencies: season_manager.lua, training_screen.lua, lineup_screen.lua,
---               schedule_screen.lua, stats_screen.lua, scouting_screen.lua
--- Used by: main.lua
--- LÖVE Callbacks: love.update, love.draw, love.mousepressed

local SeasonMenu = {}

local SeasonManager = require("season_manager")
local UIScale = require("ui_scale")

-- Navigation screens (will be loaded lazily)
local TrainingScreen = nil
local LineupScreen = nil
local ScheduleScreen = nil
local StandingsScreen = nil
local StatsScreen = nil
local ScoutingScreen = nil

-- State
SeasonMenu.currentScreen = "training"  -- Current active screen
SeasonMenu.saveRequested = false
SeasonMenu.quitRequested = false
SeasonMenu.pauseMenuVisible = false

-- UI configuration (base values for 1600x900)
local NAV_BAR_HEIGHT = 80
local NAV_BUTTON_WIDTH = 200
local NAV_BUTTON_HEIGHT = 60
local NAV_BUTTON_SPACING = 20
local HEADER_HEIGHT = 100

-- Pause menu constants (base values for 1600x900)
local PAUSE_BUTTON_WIDTH = 300
local PAUSE_BUTTON_HEIGHT = 60
local PAUSE_BUTTON_Y = {400, 530}

-- Fonts
local teamNameFont
local recordFont
local weekFont
local navButtonFont
local pauseTitleFont
local pauseButtonFont

-- Navigation buttons (Menu button added to the left of Training)
local navButtons = {
    {id = "menu", label = "Menu", x = 0},
    {id = "training", label = "Training", x = 0},
    {id = "lineup", label = "Lineup", x = 0},
    {id = "schedule", label = "Schedule", x = 0},
    {id = "standings", label = "Standings", x = 0},
    {id = "stats", label = "Stats", x = 0},
    {id = "next_game", label = "Next Game", x = 0}
}


--- Initializes the season menu
function SeasonMenu.load()
    -- Update UI scale
    UIScale.update()

    -- Create fonts
    teamNameFont = love.graphics.newFont(UIScale.scaleFontSize(36))
    recordFont = love.graphics.newFont(UIScale.scaleFontSize(24))
    weekFont = love.graphics.newFont(UIScale.scaleFontSize(24))
    navButtonFont = love.graphics.newFont(UIScale.scaleFontSize(22))
    pauseTitleFont = love.graphics.newFont(UIScale.scaleFontSize(48))
    pauseButtonFont = love.graphics.newFont(UIScale.scaleFontSize(28))

    -- Calculate nav button positions (centered at bottom)
    local scaledButtonWidth = UIScale.scaleWidth(NAV_BUTTON_WIDTH)
    local scaledButtonSpacing = UIScale.scaleUniform(NAV_BUTTON_SPACING)
    local totalWidth = (#navButtons * scaledButtonWidth) + ((#navButtons - 1) * scaledButtonSpacing)
    local startX = (UIScale.getWidth() - totalWidth) / 2

    for i, button in ipairs(navButtons) do
        button.x = startX + ((i - 1) * (scaledButtonWidth + scaledButtonSpacing))
    end

    -- Load screens lazily
    if not TrainingScreen then
        TrainingScreen = require("training_screen")
    end
    if not LineupScreen then
        LineupScreen = require("lineup_screen")
    end
    if not ScheduleScreen then
        ScheduleScreen = require("schedule_screen")
    end
    if not StandingsScreen then
        StandingsScreen = require("standings_screen")
    end
    if not StatsScreen then
        StatsScreen = require("stats_screen")
    end
    if not ScoutingScreen then
        ScoutingScreen = require("scouting_screen")
    end

    -- Start at training if in training phase, otherwise preparation
    if SeasonManager.currentPhase == SeasonManager.PHASE.TRAINING then
        SeasonMenu.currentScreen = "training"
        TrainingScreen.load()
    else
        SeasonMenu.currentScreen = "lineup"
        LineupScreen.load()
    end

    SeasonMenu.saveRequested = false
    SeasonMenu.quitRequested = false
    SeasonMenu.pauseMenuVisible = false
end

--- LÖVE Callback: Update Logic
--- @param dt number Delta time in seconds
function SeasonMenu.update(dt)
    -- Update current screen
    if SeasonMenu.currentScreen == "training" and TrainingScreen then
        TrainingScreen.update(dt)
    elseif SeasonMenu.currentScreen == "lineup" and LineupScreen then
        LineupScreen.update(dt)
    elseif SeasonMenu.currentScreen == "schedule" and ScheduleScreen then
        ScheduleScreen.update(dt)
    elseif SeasonMenu.currentScreen == "standings" and StandingsScreen then
        StandingsScreen.update(dt)
    elseif SeasonMenu.currentScreen == "stats" and StatsScreen then
        StatsScreen.update(dt)
    elseif SeasonMenu.currentScreen == "next_game" and ScoutingScreen then
        ScoutingScreen.update(dt)
    end
end

--- LÖVE Callback: Draw UI
function SeasonMenu.draw()
    -- Background
    love.graphics.setColor(0.1, 0.1, 0.15)
    love.graphics.rectangle("fill", 0, 0, UIScale.getWidth(), UIScale.getHeight())

    -- Draw header
    SeasonMenu.drawHeader()

    -- Draw current screen content
    local scaledHeaderHeight = UIScale.scaleHeight(HEADER_HEIGHT)
    love.graphics.push()
    love.graphics.translate(0, scaledHeaderHeight)

    if SeasonMenu.currentScreen == "training" and TrainingScreen then
        TrainingScreen.draw()
    elseif SeasonMenu.currentScreen == "lineup" and LineupScreen then
        LineupScreen.draw()
    elseif SeasonMenu.currentScreen == "schedule" and ScheduleScreen then
        ScheduleScreen.draw()
    elseif SeasonMenu.currentScreen == "standings" and StandingsScreen then
        StandingsScreen.draw()
    elseif SeasonMenu.currentScreen == "stats" and StatsScreen then
        StatsScreen.draw()
    elseif SeasonMenu.currentScreen == "next_game" and ScoutingScreen then
        ScoutingScreen.draw()
    end

    love.graphics.pop()

    -- Draw navigation bar
    SeasonMenu.drawNavigationBar()

    -- Draw pause menu overlay if visible
    if SeasonMenu.pauseMenuVisible then
        SeasonMenu.drawPauseMenu()
    end
end

--- Draws the header with team info
function SeasonMenu.drawHeader()
    -- Header background
    local scaledHeaderHeight = UIScale.scaleHeight(HEADER_HEIGHT)
    love.graphics.setColor(0.15, 0.15, 0.2)
    love.graphics.rectangle("fill", 0, 0, UIScale.getWidth(), scaledHeaderHeight)

    if not SeasonManager.playerTeam then
        return
    end

    local leftX = UIScale.scaleX(50)

    -- Team name
    love.graphics.setFont(teamNameFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(SeasonManager.playerTeam.name, leftX, UIScale.scaleY(25))

    -- Record
    love.graphics.setFont(recordFont)
    love.graphics.setColor(0.8, 0.8, 0.9)
    local recordText = string.format("Record: %s", SeasonManager.playerTeam:getRecordString())
    love.graphics.print(recordText, leftX, UIScale.scaleY(65))

    -- Week number (centered)
    love.graphics.setFont(weekFont)
    local weekText = "Week: "
    if SeasonManager.inPlayoffs then
        if SeasonManager.playoffBracket.currentRound == "wildcard" then
            weekText = "Playoffs: Wild Card"
        elseif SeasonManager.playoffBracket.currentRound == "divisional" then
            weekText = "Playoffs: Divisional"
        elseif SeasonManager.playoffBracket.currentRound == "conference" then
            weekText = "Playoffs: Conference"
        elseif SeasonManager.playoffBracket.currentRound == "championship" then
            weekText = "Playoffs: Championship"
        end
    else
        weekText = string.format("Week: %d / 17", SeasonManager.currentWeek)
    end
    local weekWidth = weekFont:getWidth(weekText)
    love.graphics.print(weekText, UIScale.centerX(weekWidth), UIScale.scaleY(30))

    -- Cash (only show during training phase or preparation)
    if SeasonManager.currentPhase ~= SeasonManager.PHASE.MATCH then
        love.graphics.setColor(0.3, 0.8, 0.3)
        local cashText = string.format("Cash: $%d", SeasonManager.playerTeam.cash)
        local cashWidth = weekFont:getWidth(cashText)
        love.graphics.print(cashText, UIScale.centerX(cashWidth), UIScale.scaleY(60))
    end
end

--- Draws the bottom navigation bar
function SeasonMenu.drawNavigationBar()
    local scaledNavBarHeight = UIScale.scaleHeight(NAV_BAR_HEIGHT)
    local navBarY = UIScale.getHeight() - scaledNavBarHeight
    local scaledButtonWidth = UIScale.scaleWidth(NAV_BUTTON_WIDTH)
    local scaledButtonHeight = UIScale.scaleHeight(NAV_BUTTON_HEIGHT)
    local buttonPadding = UIScale.scaleHeight(10)

    -- Navigation bar background
    love.graphics.setColor(0.15, 0.15, 0.2)
    love.graphics.rectangle("fill", 0, navBarY, UIScale.getWidth(), scaledNavBarHeight)

    -- Navigation buttons
    local mx, my = love.mouse.getPosition()

    for _, button in ipairs(navButtons) do
        local isActive = button.id == SeasonMenu.currentScreen
        local buttonY = navBarY + buttonPadding
        local hovering = mx >= button.x and mx <= button.x + scaledButtonWidth and
                        my >= buttonY and my <= buttonY + scaledButtonHeight

        -- Button background
        if isActive then
            love.graphics.setColor(0.3, 0.5, 0.7)
        elseif hovering then
            love.graphics.setColor(0.25, 0.25, 0.3)
        else
            love.graphics.setColor(0.2, 0.2, 0.25)
        end

        love.graphics.rectangle("fill", button.x, buttonY, scaledButtonWidth, scaledButtonHeight)

        -- Button border
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.setLineWidth(UIScale.scaleUniform(2))
        love.graphics.rectangle("line", button.x, buttonY, scaledButtonWidth, scaledButtonHeight)

        -- Button text
        love.graphics.setFont(navButtonFont)
        if isActive then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.8, 0.8, 0.9)
        end

        local textWidth = navButtonFont:getWidth(button.label)
        love.graphics.print(button.label, button.x + (scaledButtonWidth - textWidth) / 2, buttonY + UIScale.scaleHeight(15))
    end
end

--- LÖVE Callback: Mouse Pressed
--- @param x number Mouse X position
--- @param y number Mouse Y position
--- @param button number Mouse button (1 = left)
function SeasonMenu.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    -- Check pause menu buttons if visible
    if SeasonMenu.pauseMenuVisible then
        local scaledPauseButtonWidth = UIScale.scaleWidth(PAUSE_BUTTON_WIDTH)
        local scaledPauseButtonHeight = UIScale.scaleHeight(PAUSE_BUTTON_HEIGHT)
        local pauseButtonX = UIScale.centerX(scaledPauseButtonWidth)

        -- Save button
        local saveButtonY = UIScale.scaleY(PAUSE_BUTTON_Y[1])
        if x >= pauseButtonX and x <= pauseButtonX + scaledPauseButtonWidth and
           y >= saveButtonY and y <= saveButtonY + scaledPauseButtonHeight then
            SeasonMenu.saveRequested = true
            SeasonMenu.pauseMenuVisible = false
            return
        end

        -- Quit button
        local quitButtonY = UIScale.scaleY(PAUSE_BUTTON_Y[2])
        if x >= pauseButtonX and x <= pauseButtonX + scaledPauseButtonWidth and
           y >= quitButtonY and y <= quitButtonY + scaledPauseButtonHeight then
            SeasonMenu.quitRequested = true
            SeasonMenu.pauseMenuVisible = false
            return
        end

        -- Click outside menu closes it
        SeasonMenu.pauseMenuVisible = false
        return
    end

    -- Check navigation buttons
    local scaledNavBarHeight = UIScale.scaleHeight(NAV_BAR_HEIGHT)
    local navBarY = UIScale.getHeight() - scaledNavBarHeight
    local scaledButtonWidth = UIScale.scaleWidth(NAV_BUTTON_WIDTH)
    local scaledButtonHeight = UIScale.scaleHeight(NAV_BUTTON_HEIGHT)
    local buttonPadding = UIScale.scaleHeight(10)

    for _, btn in ipairs(navButtons) do
        local buttonY = navBarY + buttonPadding
        if x >= btn.x and x <= btn.x + scaledButtonWidth and
           y >= buttonY and y <= buttonY + scaledButtonHeight then
            if btn.id == "menu" then
                SeasonMenu.pauseMenuVisible = true
            else
                SeasonMenu.switchScreen(btn.id)
            end
            return
        end
    end

    -- Forward click to current screen
    local adjustedY = y - UIScale.scaleHeight(HEADER_HEIGHT)
    if SeasonMenu.currentScreen == "training" and TrainingScreen and TrainingScreen.mousepressed then
        TrainingScreen.mousepressed(x, adjustedY, button)
    elseif SeasonMenu.currentScreen == "lineup" and LineupScreen and LineupScreen.mousepressed then
        LineupScreen.mousepressed(x, adjustedY, button)
    elseif SeasonMenu.currentScreen == "schedule" and ScheduleScreen and ScheduleScreen.mousepressed then
        ScheduleScreen.mousepressed(x, adjustedY, button)
    elseif SeasonMenu.currentScreen == "standings" and StandingsScreen and StandingsScreen.mousepressed then
        StandingsScreen.mousepressed(x, adjustedY, button)
    elseif SeasonMenu.currentScreen == "stats" and StatsScreen and StatsScreen.mousepressed then
        StatsScreen.mousepressed(x, adjustedY, button)
    elseif SeasonMenu.currentScreen == "next_game" and ScoutingScreen and ScoutingScreen.mousepressed then
        ScoutingScreen.mousepressed(x, adjustedY, button)
    end
end

--- Draws the pause menu overlay
function SeasonMenu.drawPauseMenu()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, UIScale.getWidth(), UIScale.getHeight())

    -- Title
    love.graphics.setFont(pauseTitleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PAUSED", 0, UIScale.scaleY(300), UIScale.getWidth(), "center")

    -- Buttons
    local mx, my = love.mouse.getPosition()
    local pauseButtons = {"Save", "Quit"}
    love.graphics.setFont(pauseButtonFont)

    local scaledPauseButtonWidth = UIScale.scaleWidth(PAUSE_BUTTON_WIDTH)
    local scaledPauseButtonHeight = UIScale.scaleHeight(PAUSE_BUTTON_HEIGHT)
    local scaledRadius = UIScale.scaleUniform(10)

    for i, label in ipairs(pauseButtons) do
        local x = UIScale.centerX(scaledPauseButtonWidth)
        local y = UIScale.scaleY(PAUSE_BUTTON_Y[i])
        local hovering = mx >= x and mx <= x + scaledPauseButtonWidth and
                        my >= y and my <= y + scaledPauseButtonHeight

        -- Button background
        if hovering then
            love.graphics.setColor(0.3, 0.5, 0.7, 0.8)
        else
            love.graphics.setColor(0.2, 0.3, 0.4, 0.6)
        end
        love.graphics.rectangle("fill", x, y, scaledPauseButtonWidth, scaledPauseButtonHeight, scaledRadius, scaledRadius)

        -- Button border
        if hovering then
            love.graphics.setColor(0.5, 0.7, 1.0)
            love.graphics.setLineWidth(UIScale.scaleUniform(3))
        else
            love.graphics.setColor(0.4, 0.5, 0.6)
            love.graphics.setLineWidth(UIScale.scaleUniform(2))
        end
        love.graphics.rectangle("line", x, y, scaledPauseButtonWidth, scaledPauseButtonHeight, scaledRadius, scaledRadius)

        -- Button text
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(label, x, y + UIScale.scaleHeight(15), scaledPauseButtonWidth, "center")
    end
end

--- LÖVE Callback: Keyboard Pressed
--- @param key string The key that was pressed
function SeasonMenu.keypressed(key)
    if key == "escape" then
        SeasonMenu.pauseMenuVisible = not SeasonMenu.pauseMenuVisible
    end
end

--- Switches to a different screen
--- @param screenId string The screen ID to switch to
function SeasonMenu.switchScreen(screenId)
    SeasonMenu.currentScreen = screenId

    -- Load the new screen
    if screenId == "training" and TrainingScreen then
        TrainingScreen.load()
    elseif screenId == "lineup" and LineupScreen then
        LineupScreen.load()
    elseif screenId == "schedule" and ScheduleScreen then
        ScheduleScreen.load()
    elseif screenId == "standings" and StandingsScreen then
        StandingsScreen.load()
    elseif screenId == "stats" and StatsScreen then
        StatsScreen.load()
    elseif screenId == "next_game" and ScoutingScreen then
        ScoutingScreen.load()
    end
end

--- Checks if save was requested
--- @return boolean True if save button clicked
function SeasonMenu.isSaveRequested()
    return SeasonMenu.saveRequested
end

--- Checks if quit was requested
--- @return boolean True if quit button clicked
function SeasonMenu.isQuitRequested()
    return SeasonMenu.quitRequested
end

--- LÖVE Callback: Mouse Wheel Moved
--- @param x number Horizontal scroll amount
--- @param y number Vertical scroll amount
function SeasonMenu.wheelmoved(x, y)
    -- Forward scroll to current screen if it supports it
    if SeasonMenu.currentScreen == "schedule" and ScheduleScreen and ScheduleScreen.wheelmoved then
        ScheduleScreen.wheelmoved(y)
    elseif SeasonMenu.currentScreen == "stats" and StatsScreen and StatsScreen.wheelmoved then
        StatsScreen.wheelmoved(y)
    end
end

--- LÖVE Callback: Mouse Moved
--- @param x number Mouse X position
--- @param y number Mouse Y position
function SeasonMenu.mousemoved(x, y)
    -- Adjust y for header offset
    local adjustedY = y - UIScale.scaleHeight(HEADER_HEIGHT)

    -- Forward to current screen if it supports it
    if SeasonMenu.currentScreen == "schedule" and ScheduleScreen and ScheduleScreen.mousemoved then
        ScheduleScreen.mousemoved(x, adjustedY)
    elseif SeasonMenu.currentScreen == "stats" and StatsScreen and StatsScreen.mousemoved then
        StatsScreen.mousemoved(x, adjustedY)
    end
end

--- LÖVE Callback: Mouse Released
--- @param x number Mouse X position
--- @param y number Mouse Y position
--- @param button number Mouse button
function SeasonMenu.mousereleased(x, y, button)
    -- Adjust y for header offset
    local adjustedY = y - UIScale.scaleHeight(HEADER_HEIGHT)

    -- Forward to current screen if it supports it
    if SeasonMenu.currentScreen == "schedule" and ScheduleScreen and ScheduleScreen.mousereleased then
        ScheduleScreen.mousereleased(x, adjustedY, button)
    elseif SeasonMenu.currentScreen == "stats" and StatsScreen and StatsScreen.mousereleased then
        StatsScreen.mousereleased(x, adjustedY, button)
    end
end

return SeasonMenu
