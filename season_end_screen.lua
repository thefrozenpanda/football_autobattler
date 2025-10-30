--- season_end_screen.lua
--- Season End Screen
---
--- Displays end-of-season results based on player's performance:
--- - Championship Winner: Congratulations screen
--- - Made playoffs but lost: Good season, better luck next year
--- - Missed playoffs: Better luck next season
---
--- Includes option to return to main menu or start new season.
---
--- Dependencies: season_manager.lua
--- Used by: main.lua
--- LÖVE Callbacks: love.update, love.draw, love.mousepressed

local SeasonEndScreen = {}

local SeasonManager = require("season_manager")

-- State
SeasonEndScreen.outcome = "missed_playoffs"  -- "champion", "playoffs", "missed_playoffs"
SeasonEndScreen.finalRecord = ""
SeasonEndScreen.returnToMenuRequested = false
SeasonEndScreen.newSeasonRequested = false

-- UI configuration
local SCREEN_WIDTH = 1600
local SCREEN_HEIGHT = 900
local BUTTON_WIDTH = 250
local BUTTON_HEIGHT = 60
local BUTTON_SPACING = 30

--- Initializes the season end screen
function SeasonEndScreen.load()
    SeasonEndScreen.returnToMenuRequested = false
    SeasonEndScreen.newSeasonRequested = false

    -- Determine outcome
    if not SeasonManager.playerTeam then
        SeasonEndScreen.outcome = "missed_playoffs"
        SeasonEndScreen.finalRecord = "0-0"
        return
    end

    SeasonEndScreen.finalRecord = SeasonManager.playerTeam:getRecordString()

    -- Check if player won championship
    if SeasonManager.inPlayoffs and SeasonManager.playoffBracket.currentRound == "championship" then
        -- Check if championship was played and won
        if SeasonManager.playoffBracket.championship and #SeasonManager.playoffBracket.championship > 0 then
            local championshipGame = SeasonManager.playoffBracket.championship[1]
            if championshipGame.played then
                -- Determine winner
                local playerWon = false
                if championshipGame.homeTeam == SeasonManager.playerTeam and championshipGame.homeScore > championshipGame.awayScore then
                    playerWon = true
                elseif championshipGame.awayTeam == SeasonManager.playerTeam and championshipGame.awayScore > championshipGame.homeScore then
                    playerWon = true
                end

                if playerWon then
                    SeasonEndScreen.outcome = "champion"
                else
                    SeasonEndScreen.outcome = "playoffs"
                end
            else
                SeasonEndScreen.outcome = "playoffs"
            end
        else
            SeasonEndScreen.outcome = "playoffs"
        end
    elseif SeasonManager.inPlayoffs then
        SeasonEndScreen.outcome = "playoffs"
    else
        SeasonEndScreen.outcome = "missed_playoffs"
    end
end

--- LÖVE Callback: Update Logic
--- @param dt number Delta time in seconds
function SeasonEndScreen.update(dt)
    -- Nothing to update
end

--- LÖVE Callback: Draw UI
function SeasonEndScreen.draw()
    -- Background
    love.graphics.setColor(0.1, 0.1, 0.15)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    local yOffset = 150

    -- Title based on outcome
    love.graphics.setFont(love.graphics.newFont(56))

    if SeasonEndScreen.outcome == "champion" then
        love.graphics.setColor(1, 0.8, 0.2)
        local titleText = "CHAMPIONS!"
        local titleWidth = love.graphics.getFont():getWidth(titleText)
        love.graphics.print(titleText, (SCREEN_WIDTH - titleWidth) / 2, yOffset)

        yOffset = yOffset + 100

        love.graphics.setFont(love.graphics.newFont(32))
        love.graphics.setColor(0.9, 0.9, 1)
        local congratsText = string.format("Congratulations! %s won the championship!", SeasonManager.playerTeam.name)
        local congratsWidth = love.graphics.getFont():getWidth(congratsText)
        love.graphics.print(congratsText, (SCREEN_WIDTH - congratsWidth) / 2, yOffset)

    elseif SeasonEndScreen.outcome == "playoffs" then
        love.graphics.setColor(0.7, 0.7, 0.9)
        local titleText = "Season Complete"
        local titleWidth = love.graphics.getFont():getWidth(titleText)
        love.graphics.print(titleText, (SCREEN_WIDTH - titleWidth) / 2, yOffset)

        yOffset = yOffset + 100

        love.graphics.setFont(love.graphics.newFont(32))
        love.graphics.setColor(0.8, 0.8, 0.9)
        local messageText = "Good season! You made the playoffs."
        local messageWidth = love.graphics.getFont():getWidth(messageText)
        love.graphics.print(messageText, (SCREEN_WIDTH - messageWidth) / 2, yOffset)

        yOffset = yOffset + 50

        love.graphics.setFont(love.graphics.newFont(28))
        love.graphics.setColor(0.7, 0.7, 0.8)
        local encourageText = "Better luck next year!"
        local encourageWidth = love.graphics.getFont():getWidth(encourageText)
        love.graphics.print(encourageText, (SCREEN_WIDTH - encourageWidth) / 2, yOffset)

    else
        love.graphics.setColor(0.7, 0.5, 0.5)
        local titleText = "Season Complete"
        local titleWidth = love.graphics.getFont():getWidth(titleText)
        love.graphics.print(titleText, (SCREEN_WIDTH - titleWidth) / 2, yOffset)

        yOffset = yOffset + 100

        love.graphics.setFont(love.graphics.newFont(32))
        love.graphics.setColor(0.8, 0.7, 0.7)
        local messageText = "You missed the playoffs this season."
        local messageWidth = love.graphics.getFont():getWidth(messageText)
        love.graphics.print(messageText, (SCREEN_WIDTH - messageWidth) / 2, yOffset)

        yOffset = yOffset + 50

        love.graphics.setFont(love.graphics.newFont(28))
        love.graphics.setColor(0.7, 0.7, 0.8)
        local encourageText = "Train harder and come back next season!"
        local encourageWidth = love.graphics.getFont():getWidth(encourageText)
        love.graphics.print(encourageText, (SCREEN_WIDTH - encourageWidth) / 2, yOffset)
    end

    yOffset = yOffset + 100

    -- Final record
    love.graphics.setFont(love.graphics.newFont(36))
    love.graphics.setColor(1, 1, 1)
    local recordText = string.format("Final Record: %s", SeasonEndScreen.finalRecord)
    local recordWidth = love.graphics.getFont():getWidth(recordText)
    love.graphics.print(recordText, (SCREEN_WIDTH - recordWidth) / 2, yOffset)

    yOffset = yOffset + 150

    -- Buttons
    local totalButtonWidth = (BUTTON_WIDTH * 2) + BUTTON_SPACING
    local buttonStartX = (SCREEN_WIDTH - totalButtonWidth) / 2

    SeasonEndScreen.drawButton("Main Menu", buttonStartX, yOffset, BUTTON_WIDTH, BUTTON_HEIGHT, "menu")
    SeasonEndScreen.drawButton("New Season", buttonStartX + BUTTON_WIDTH + BUTTON_SPACING, yOffset, BUTTON_WIDTH, BUTTON_HEIGHT, "new_season")
end

--- Draws a button
--- @param text string Button text
--- @param x number X position
--- @param y number Y position
--- @param width number Width
--- @param height number Height
--- @param id string Button ID
function SeasonEndScreen.drawButton(text, x, y, width, height, id)
    local mx, my = love.mouse.getPosition()
    local hovering = mx >= x and mx <= x + width and my >= y and my <= y + height

    -- Background
    if hovering then
        love.graphics.setColor(0.3, 0.4, 0.5)
    else
        love.graphics.setColor(0.2, 0.25, 0.3)
    end
    love.graphics.rectangle("fill", x, y, width, height)

    -- Border
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", x, y, width, height)

    -- Text
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.setColor(1, 1, 1)
    local textWidth = love.graphics.getFont():getWidth(text)
    love.graphics.print(text, x + (width - textWidth) / 2, y + 15)
end

--- LÖVE Callback: Mouse Pressed
--- @param x number Mouse X position
--- @param y number Mouse Y position
--- @param button number Mouse button
function SeasonEndScreen.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    local yOffset = 150

    -- Calculate button Y position (same logic as draw)
    if SeasonEndScreen.outcome == "champion" then
        yOffset = yOffset + 100 + 100
    else
        yOffset = yOffset + 100 + 50 + 50
    end

    yOffset = yOffset + 100 + 150

    local totalButtonWidth = (BUTTON_WIDTH * 2) + BUTTON_SPACING
    local buttonStartX = (SCREEN_WIDTH - totalButtonWidth) / 2

    -- Main Menu button
    if x >= buttonStartX and x <= buttonStartX + BUTTON_WIDTH and
       y >= yOffset and y <= yOffset + BUTTON_HEIGHT then
        SeasonEndScreen.returnToMenuRequested = true
    end

    -- New Season button
    local newSeasonX = buttonStartX + BUTTON_WIDTH + BUTTON_SPACING
    if x >= newSeasonX and x <= newSeasonX + BUTTON_WIDTH and
       y >= yOffset and y <= yOffset + BUTTON_HEIGHT then
        SeasonEndScreen.newSeasonRequested = true
    end
end

--- Checks if return to menu was requested
--- @return boolean True if button clicked
function SeasonEndScreen.isReturnToMenuRequested()
    return SeasonEndScreen.returnToMenuRequested
end

--- Checks if new season was requested
--- @return boolean True if button clicked
function SeasonEndScreen.isNewSeasonRequested()
    return SeasonEndScreen.newSeasonRequested
end

return SeasonEndScreen
