--- match_result_popup.lua
--- Match Result Display Popup
---
--- Displays the final score after a simulated match.
--- Shows player score, opponent score, and result (Win/Loss).
--- Includes a "Continue" button to proceed to next screen.
---
--- Dependencies: ui_scale.lua
--- Used by: main.lua
--- LÖVE Callbacks: love.draw, love.mousepressed

local MatchResultPopup = {}
local UIScale = require("ui_scale")
local Coach = require("coach")

MatchResultPopup.active = false
MatchResultPopup.playerScore = 0
MatchResultPopup.opponentScore = 0
MatchResultPopup.playerTeamName = ""
MatchResultPopup.opponentTeamName = ""
MatchResultPopup.winningCoachStyle = ""
MatchResultPopup.offensiveMVP = nil
MatchResultPopup.defensiveMVP = nil
MatchResultPopup.continueRequested = false

-- UI configuration (base values for 1600x900)
local POPUP_WIDTH = 700
local POPUP_HEIGHT = 550
local BUTTON_WIDTH = 250
local BUTTON_HEIGHT = 50

-- Fonts
local titleFont
local scoreFont
local teamFont
local buttonFont
local infoFont
local mvpFont

--- Initializes the match result popup
function MatchResultPopup.init()
    UIScale.update()
    titleFont = love.graphics.newFont(UIScale.scaleFontSize(36))
    scoreFont = love.graphics.newFont(UIScale.scaleFontSize(48))
    teamFont = love.graphics.newFont(UIScale.scaleFontSize(24))
    buttonFont = love.graphics.newFont(UIScale.scaleFontSize(26))
    infoFont = love.graphics.newFont(UIScale.scaleFontSize(20))
    mvpFont = love.graphics.newFont(UIScale.scaleFontSize(18))
end

--- Shows the match result popup
--- @param playerScore number Player's final score
--- @param opponentScore number Opponent's final score
--- @param playerTeamName string Player's team name
--- @param opponentTeamName string Opponent's team name
--- @param winningCoachId number The winning coach's ID
--- @param offensiveMVP table|nil The offensive MVP card (can be nil for simulated games)
--- @param defensiveMVP table|nil The defensive MVP card (can be nil for simulated games)
function MatchResultPopup.show(playerScore, opponentScore, playerTeamName, opponentTeamName, winningCoachId, offensiveMVP, defensiveMVP)
    MatchResultPopup.active = true
    MatchResultPopup.playerScore = playerScore
    MatchResultPopup.opponentScore = opponentScore
    MatchResultPopup.playerTeamName = playerTeamName
    MatchResultPopup.opponentTeamName = opponentTeamName
    MatchResultPopup.offensiveMVP = offensiveMVP
    MatchResultPopup.defensiveMVP = defensiveMVP
    MatchResultPopup.continueRequested = false

    -- Get winning coach style
    local coachData = Coach.getById(winningCoachId)
    if coachData then
        MatchResultPopup.winningCoachStyle = coachData.style or "Unknown"
    else
        MatchResultPopup.winningCoachStyle = "Unknown"
    end
end

--- Hides the match result popup
function MatchResultPopup.hide()
    MatchResultPopup.active = false
    MatchResultPopup.continueRequested = false
end

--- Checks if popup is active
--- @return boolean True if popup is showing
function MatchResultPopup.isActive()
    return MatchResultPopup.active
end

--- Checks if continue was requested
--- @return boolean True if continue button was clicked
function MatchResultPopup.isContinueRequested()
    return MatchResultPopup.continueRequested
end

--- LÖVE Callback: Draw UI
function MatchResultPopup.draw()
    if not MatchResultPopup.active then
        return
    end

    -- Initialize fonts if needed
    if not titleFont then
        MatchResultPopup.init()
    end

    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, UIScale.getWidth(), UIScale.getHeight())

    -- Popup window
    local scaledPopupWidth = UIScale.scaleWidth(POPUP_WIDTH)
    local scaledPopupHeight = UIScale.scaleHeight(POPUP_HEIGHT)
    local popupX = UIScale.centerX(scaledPopupWidth)
    local popupY = UIScale.centerY(scaledPopupHeight)

    love.graphics.setColor(0.15, 0.15, 0.2)
    love.graphics.rectangle("fill", popupX, popupY, scaledPopupWidth, scaledPopupHeight)

    -- Border
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.setLineWidth(UIScale.scaleUniform(3))
    love.graphics.rectangle("line", popupX, popupY, scaledPopupWidth, scaledPopupHeight)

    local contentY = popupY + UIScale.scaleHeight(30)

    -- Determine winner
    local playerWon = MatchResultPopup.playerScore > MatchResultPopup.opponentScore
    local isTie = MatchResultPopup.playerScore == MatchResultPopup.opponentScore
    local winnerName = playerWon and MatchResultPopup.playerTeamName or MatchResultPopup.opponentTeamName

    -- Title (Winner announcement) - matches manual match format
    love.graphics.setFont(titleFont)
    local titleText = isTie and "TIE GAME" or (winnerName .. " WINS!")
    love.graphics.setColor(1, 0.8, 0.2)  -- Gold color like manual match
    local titleWidth = titleFont:getWidth(titleText)
    love.graphics.print(titleText, popupX + (scaledPopupWidth - titleWidth) / 2, contentY)

    contentY = contentY + UIScale.scaleHeight(60)

    -- Coach style (matches manual match format)
    love.graphics.setFont(teamFont)
    love.graphics.setColor(0.8, 0.8, 0.8)
    local coachText = isTie and "No Winner" or MatchResultPopup.winningCoachStyle
    local coachWidth = teamFont:getWidth(coachText)
    love.graphics.print(coachText, popupX + (scaledPopupWidth - coachWidth) / 2, contentY)

    contentY = contentY + UIScale.scaleHeight(45)

    -- Final Score (matches manual match format exactly)
    love.graphics.setFont(infoFont)
    love.graphics.setColor(1, 1, 1)
    local scoreText = string.format("Final Score:  Player %d - %d AI",
        MatchResultPopup.playerScore,
        MatchResultPopup.opponentScore)
    local scoreWidth = infoFont:getWidth(scoreText)
    love.graphics.print(scoreText, popupX + (scaledPopupWidth - scoreWidth) / 2, contentY)

    contentY = contentY + UIScale.scaleHeight(50)

    -- Players of the Game (matches manual match format)
    love.graphics.setFont(teamFont)
    love.graphics.setColor(0.9, 0.6, 0.3)  -- Orange color like manual match
    local pogText = "Players of the Game"
    local pogWidth = teamFont:getWidth(pogText)
    love.graphics.print(pogText, popupX + (scaledPopupWidth - pogWidth) / 2, contentY)

    contentY = contentY + UIScale.scaleHeight(50)

    -- Offensive MVP (matches manual match format)
    love.graphics.setFont(infoFont)
    love.graphics.setColor(0.3, 0.8, 0.3)  -- Green color like manual match
    love.graphics.printf("Offensive Player:", popupX + UIScale.scaleWidth(50), contentY,
        scaledPopupWidth - UIScale.scaleWidth(100), "left")

    contentY = contentY + UIScale.scaleHeight(30)

    love.graphics.setColor(1, 1, 1)
    if MatchResultPopup.offensiveMVP and MatchResultPopup.offensiveMVP.position ~= "N/A" then
        local offenseMVPText = string.format("%s - %.1f yards, %d TDs",
            MatchResultPopup.offensiveMVP.position,
            tonumber(MatchResultPopup.offensiveMVP.yards),
            MatchResultPopup.offensiveMVP.touchdowns)
        love.graphics.printf(offenseMVPText, popupX + UIScale.scaleWidth(50), contentY,
            scaledPopupWidth - UIScale.scaleWidth(100), "left")
    else
        love.graphics.printf("N/A", popupX + UIScale.scaleWidth(50), contentY,
            scaledPopupWidth - UIScale.scaleWidth(100), "left")
    end

    contentY = contentY + UIScale.scaleHeight(50)

    -- Defensive MVP (matches manual match format)
    love.graphics.setColor(0.3, 0.6, 0.9)  -- Blue color like manual match
    love.graphics.printf("Defensive Player:", popupX + UIScale.scaleWidth(50), contentY,
        scaledPopupWidth - UIScale.scaleWidth(100), "left")

    contentY = contentY + UIScale.scaleHeight(30)

    love.graphics.setColor(1, 1, 1)
    if MatchResultPopup.defensiveMVP and MatchResultPopup.defensiveMVP.position ~= "N/A" then
        local defenseMVPText = string.format("%s - %d slows, %d freezes, %.1f yards reduced",
            MatchResultPopup.defensiveMVP.position,
            MatchResultPopup.defensiveMVP.slows,
            MatchResultPopup.defensiveMVP.freezes,
            tonumber(MatchResultPopup.defensiveMVP.yardsReduced))
        love.graphics.printf(defenseMVPText, popupX + UIScale.scaleWidth(50), contentY,
            scaledPopupWidth - UIScale.scaleWidth(100), "left")
    else
        love.graphics.printf("N/A", popupX + UIScale.scaleWidth(50), contentY,
            scaledPopupWidth - UIScale.scaleWidth(100), "left")
    end

    -- Return to Menu button
    local scaledButtonWidth = UIScale.scaleWidth(BUTTON_WIDTH)
    local scaledButtonHeight = UIScale.scaleHeight(BUTTON_HEIGHT)
    local buttonX = popupX + (scaledPopupWidth - scaledButtonWidth) / 2
    local buttonY = popupY + scaledPopupHeight - scaledButtonHeight - UIScale.scaleHeight(20)

    local mx, my = love.mouse.getPosition()
    local hoveringButton = mx >= buttonX and mx <= buttonX + scaledButtonWidth and
                          my >= buttonY and my <= buttonY + scaledButtonHeight

    -- Button background
    if hoveringButton then
        love.graphics.setColor(0.3, 0.5, 0.7)
    else
        love.graphics.setColor(0.2, 0.4, 0.6)
    end
    love.graphics.rectangle("fill", buttonX, buttonY, scaledButtonWidth, scaledButtonHeight)

    -- Button border
    love.graphics.setColor(0.5, 0.7, 0.9)
    love.graphics.setLineWidth(UIScale.scaleUniform(2))
    love.graphics.rectangle("line", buttonX, buttonY, scaledButtonWidth, scaledButtonHeight)

    -- Button text
    love.graphics.setFont(buttonFont)
    love.graphics.setColor(1, 1, 1)
    local buttonText = "Return to Menu"
    local buttonTextWidth = buttonFont:getWidth(buttonText)
    love.graphics.print(buttonText, buttonX + (scaledButtonWidth - buttonTextWidth) / 2, buttonY + UIScale.scaleHeight(12))
end

--- LÖVE Callback: Mouse Pressed
--- @param x number Mouse X position
--- @param y number Mouse Y position
--- @param button number Mouse button
function MatchResultPopup.mousepressed(x, y, button)
    if not MatchResultPopup.active or button ~= 1 then
        return
    end

    local scaledPopupWidth = UIScale.scaleWidth(POPUP_WIDTH)
    local scaledPopupHeight = UIScale.scaleHeight(POPUP_HEIGHT)
    local popupX = UIScale.centerX(scaledPopupWidth)
    local popupY = UIScale.centerY(scaledPopupHeight)

    local scaledButtonWidth = UIScale.scaleWidth(BUTTON_WIDTH)
    local scaledButtonHeight = UIScale.scaleHeight(BUTTON_HEIGHT)
    local buttonX = popupX + (scaledPopupWidth - scaledButtonWidth) / 2
    local buttonY = popupY + scaledPopupHeight - scaledButtonHeight - UIScale.scaleHeight(20)

    if x >= buttonX and x <= buttonX + scaledButtonWidth and
       y >= buttonY and y <= buttonY + scaledButtonHeight then
        MatchResultPopup.continueRequested = true
    end
end

return MatchResultPopup
