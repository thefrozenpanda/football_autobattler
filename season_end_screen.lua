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
local flux = require("lib.flux")
local UIScale = require("ui_scale")

-- State
SeasonEndScreen.outcome = "missed_playoffs"  -- "champion", "playoffs", "missed_playoffs"
SeasonEndScreen.finalRecord = ""
SeasonEndScreen.returnToMenuRequested = false
SeasonEndScreen.newSeasonRequested = false
SeasonEndScreen.backRequested = false

-- Animation state
local titleAnimState = {scale = 1.0, glow = 0}
local pulseCount = 0

-- UI configuration (base values for 1600x900)
local BUTTON_WIDTH = 250
local BUTTON_HEIGHT = 60
local BUTTON_SPACING = 30

-- Fonts
local titleFont
local subtitleFont
local messageFont
local encourageFont
local recordFont
local buttonFont

--- Initializes the season end screen
function SeasonEndScreen.load()
    -- Update UI scale
    UIScale.update()

    -- Create fonts
    titleFont = love.graphics.newFont(UIScale.scaleFontSize(56))
    subtitleFont = love.graphics.newFont(UIScale.scaleFontSize(32))
    messageFont = love.graphics.newFont(UIScale.scaleFontSize(32))
    encourageFont = love.graphics.newFont(UIScale.scaleFontSize(28))
    recordFont = love.graphics.newFont(UIScale.scaleFontSize(36))
    buttonFont = love.graphics.newFont(UIScale.scaleFontSize(28))

    SeasonEndScreen.returnToMenuRequested = false
    SeasonEndScreen.newSeasonRequested = false
    SeasonEndScreen.backRequested = false

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

    -- Start trophy pulse animation for champions (5 pulses)
    if SeasonEndScreen.outcome == "champion" then
        titleAnimState = {scale = 1.0, glow = 0}
        pulseCount = 0

        local function pulse()
            if pulseCount >= 5 then
                return  -- Stop after 5 pulses
            end

            pulseCount = pulseCount + 1
            flux.to(titleAnimState, 1.0, {scale = 1.1, glow = 0.3})
                :ease("sineinout")
                :oncomplete(function()
                    flux.to(titleAnimState, 1.0, {scale = 1.0, glow = 0})
                        :ease("sineinout")
                        :oncomplete(pulse)  -- Continue pulse
                end)
        end
        pulse()
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
    love.graphics.rectangle("fill", 0, 0, UIScale.getWidth(), UIScale.getHeight())

    local yOffset = UIScale.scaleY(150)
    local screenCenterX = UIScale.getWidth() / 2

    -- Title based on outcome
    love.graphics.setFont(titleFont)

    if SeasonEndScreen.outcome == "champion" then
        love.graphics.push()

        -- Apply glow effect
        if titleAnimState.glow > 0 then
            love.graphics.setColor(1, 1, 1, titleAnimState.glow)
            love.graphics.circle("fill", screenCenterX, yOffset + UIScale.scaleHeight(30), UIScale.scaleUniform(200))
        end

        -- Apply scale to title
        local titleText = "CHAMPIONS!"
        local titleWidth = titleFont:getWidth(titleText)
        local titleX = (UIScale.getWidth() - titleWidth) / 2
        local titleY = yOffset

        love.graphics.translate(screenCenterX, yOffset + UIScale.scaleHeight(30))
        love.graphics.scale(titleAnimState.scale, titleAnimState.scale)
        love.graphics.translate(-screenCenterX, -(yOffset + UIScale.scaleHeight(30)))

        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.print(titleText, titleX, titleY)

        love.graphics.pop()

        yOffset = yOffset + UIScale.scaleHeight(100)

        love.graphics.setFont(subtitleFont)
        love.graphics.setColor(0.9, 0.9, 1)
        local congratsText = string.format("Congratulations! %s won the championship!", SeasonManager.playerTeam.name)
        local congratsWidth = subtitleFont:getWidth(congratsText)
        love.graphics.print(congratsText, (UIScale.getWidth() - congratsWidth) / 2, yOffset)

    elseif SeasonEndScreen.outcome == "playoffs" then
        love.graphics.setColor(0.7, 0.7, 0.9)
        local titleText = "Season Complete"
        local titleWidth = titleFont:getWidth(titleText)
        love.graphics.print(titleText, (UIScale.getWidth() - titleWidth) / 2, yOffset)

        yOffset = yOffset + UIScale.scaleHeight(100)

        love.graphics.setFont(messageFont)
        love.graphics.setColor(0.8, 0.8, 0.9)
        local messageText = "Good season! You made the playoffs."
        local messageWidth = messageFont:getWidth(messageText)
        love.graphics.print(messageText, (UIScale.getWidth() - messageWidth) / 2, yOffset)

        yOffset = yOffset + UIScale.scaleHeight(50)

        love.graphics.setFont(encourageFont)
        love.graphics.setColor(0.7, 0.7, 0.8)
        local encourageText = "Better luck next year!"
        local encourageWidth = encourageFont:getWidth(encourageText)
        love.graphics.print(encourageText, (UIScale.getWidth() - encourageWidth) / 2, yOffset)

    else
        love.graphics.setColor(0.7, 0.5, 0.5)
        local titleText = "Season Complete"
        local titleWidth = titleFont:getWidth(titleText)
        love.graphics.print(titleText, (UIScale.getWidth() - titleWidth) / 2, yOffset)

        yOffset = yOffset + UIScale.scaleHeight(100)

        love.graphics.setFont(messageFont)
        love.graphics.setColor(0.8, 0.7, 0.7)
        local messageText = "You missed the playoffs this season."
        local messageWidth = messageFont:getWidth(messageText)
        love.graphics.print(messageText, (UIScale.getWidth() - messageWidth) / 2, yOffset)

        yOffset = yOffset + UIScale.scaleHeight(50)

        love.graphics.setFont(encourageFont)
        love.graphics.setColor(0.7, 0.7, 0.8)
        local encourageText = "Train harder and come back next season!"
        local encourageWidth = encourageFont:getWidth(encourageText)
        love.graphics.print(encourageText, (UIScale.getWidth() - encourageWidth) / 2, yOffset)
    end

    yOffset = yOffset + UIScale.scaleHeight(100)

    -- Final record
    love.graphics.setFont(recordFont)
    love.graphics.setColor(1, 1, 1)
    local recordText = string.format("Final Record: %s", SeasonEndScreen.finalRecord)
    local recordWidth = recordFont:getWidth(recordText)
    love.graphics.print(recordText, (UIScale.getWidth() - recordWidth) / 2, yOffset)

    yOffset = yOffset + UIScale.scaleHeight(150)

    -- Buttons (3 buttons: Back, Main Menu, New Season)
    local scaledButtonWidth = UIScale.scaleWidth(BUTTON_WIDTH)
    local scaledButtonSpacing = UIScale.scaleUniform(BUTTON_SPACING)
    local totalButtonWidth = (scaledButtonWidth * 3) + (scaledButtonSpacing * 2)
    local buttonStartX = (UIScale.getWidth() - totalButtonWidth) / 2

    SeasonEndScreen.drawButton("Back", buttonStartX, yOffset, scaledButtonWidth, UIScale.scaleHeight(BUTTON_HEIGHT), "back")
    SeasonEndScreen.drawButton("Main Menu", buttonStartX + scaledButtonWidth + scaledButtonSpacing, yOffset, scaledButtonWidth, UIScale.scaleHeight(BUTTON_HEIGHT), "menu")
    SeasonEndScreen.drawButton("New Season", buttonStartX + (scaledButtonWidth * 2) + (scaledButtonSpacing * 2), yOffset, scaledButtonWidth, UIScale.scaleHeight(BUTTON_HEIGHT), "new_season")
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
    love.graphics.setLineWidth(UIScale.scaleUniform(3))
    love.graphics.rectangle("line", x, y, width, height)

    -- Text
    love.graphics.setFont(buttonFont)
    love.graphics.setColor(1, 1, 1)
    local textWidth = buttonFont:getWidth(text)
    love.graphics.print(text, x + (width - textWidth) / 2, y + UIScale.scaleHeight(15))
end

--- LÖVE Callback: Mouse Pressed
--- @param x number Mouse X position
--- @param y number Mouse Y position
--- @param button number Mouse button
function SeasonEndScreen.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    local yOffset = UIScale.scaleY(150)

    -- Calculate button Y position (matching draw() logic exactly)
    if SeasonEndScreen.outcome == "champion" then
        yOffset = yOffset + UIScale.scaleHeight(100)  -- After title
    else
        yOffset = yOffset + UIScale.scaleHeight(100) + UIScale.scaleHeight(50)  -- After title + message
    end

    yOffset = yOffset + UIScale.scaleHeight(100)  -- After record space
    yOffset = yOffset + UIScale.scaleHeight(150)  -- Final offset to buttons

    local scaledButtonWidth = UIScale.scaleWidth(BUTTON_WIDTH)
    local scaledButtonHeight = UIScale.scaleHeight(BUTTON_HEIGHT)
    local scaledButtonSpacing = UIScale.scaleUniform(BUTTON_SPACING)
    local totalButtonWidth = (scaledButtonWidth * 3) + (scaledButtonSpacing * 2)
    local buttonStartX = (UIScale.getWidth() - totalButtonWidth) / 2

    -- Back button
    if x >= buttonStartX and x <= buttonStartX + scaledButtonWidth and
       y >= yOffset and y <= yOffset + scaledButtonHeight then
        SeasonEndScreen.backRequested = true
    end

    -- Main Menu button
    local mainMenuX = buttonStartX + scaledButtonWidth + scaledButtonSpacing
    if x >= mainMenuX and x <= mainMenuX + scaledButtonWidth and
       y >= yOffset and y <= yOffset + scaledButtonHeight then
        SeasonEndScreen.returnToMenuRequested = true
    end

    -- New Season button
    local newSeasonX = buttonStartX + (scaledButtonWidth * 2) + (scaledButtonSpacing * 2)
    if x >= newSeasonX and x <= newSeasonX + scaledButtonWidth and
       y >= yOffset and y <= yOffset + scaledButtonHeight then
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

--- Checks if back was requested
--- @return boolean True if button clicked
function SeasonEndScreen.isBackRequested()
    return SeasonEndScreen.backRequested
end

return SeasonEndScreen
