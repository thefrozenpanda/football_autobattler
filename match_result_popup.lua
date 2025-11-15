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

    -- Title (Winner announcement)
    love.graphics.setFont(titleFont)
    local titleText = ""
    local titleColor = {1, 1, 1}

    if isTie then
        titleText = "Tie Game"
        titleColor = {1, 1, 0.5}
    else
        titleText = winnerName .. " Wins!"
        titleColor = playerWon and {0.3, 1, 0.3} or {1, 0.5, 0.5}
    end

    love.graphics.setColor(titleColor)
    local titleWidth = titleFont:getWidth(titleText)
    love.graphics.print(titleText, popupX + (scaledPopupWidth - titleWidth) / 2, contentY)

    contentY = contentY + UIScale.scaleHeight(55)

    -- Winning coach style (if not a tie)
    if not isTie then
        love.graphics.setFont(infoFont)
        love.graphics.setColor(0.8, 0.8, 0.9)
        local styleText = "Winning Coach Style: " .. MatchResultPopup.winningCoachStyle
        local styleWidth = infoFont:getWidth(styleText)
        love.graphics.print(styleText, popupX + (scaledPopupWidth - styleWidth) / 2, contentY)
        contentY = contentY + UIScale.scaleHeight(40)
    else
        contentY = contentY + UIScale.scaleHeight(20)
    end

    -- Final Score
    love.graphics.setFont(teamFont)
    love.graphics.setColor(0.9, 0.9, 1)
    local scoreText = "Final Score"
    local scoreTextWidth = teamFont:getWidth(scoreText)
    love.graphics.print(scoreText, popupX + (scaledPopupWidth - scoreTextWidth) / 2, contentY)

    contentY = contentY + UIScale.scaleHeight(35)

    -- Score display
    love.graphics.setFont(scoreFont)
    love.graphics.setColor(1, 1, 1)
    local fullScoreText = string.format("%s %d - %d %s",
        MatchResultPopup.playerTeamName, MatchResultPopup.playerScore,
        MatchResultPopup.opponentScore, MatchResultPopup.opponentTeamName)
    local fullScoreWidth = scoreFont:getWidth(fullScoreText)

    -- If text is too wide, use smaller font
    if fullScoreWidth > scaledPopupWidth - UIScale.scaleWidth(40) then
        love.graphics.setFont(teamFont)
        fullScoreWidth = teamFont:getWidth(fullScoreText)
    end

    love.graphics.print(fullScoreText, popupX + (scaledPopupWidth - fullScoreWidth) / 2, contentY)

    contentY = contentY + UIScale.scaleHeight(60)

    -- Players of the Game
    love.graphics.setFont(infoFont)
    love.graphics.setColor(0.9, 0.9, 1)
    local pogText = "Players of the Game"
    local pogWidth = infoFont:getWidth(pogText)
    love.graphics.print(pogText, popupX + (scaledPopupWidth - pogWidth) / 2, contentY)

    contentY = contentY + UIScale.scaleHeight(35)

    -- Offensive MVP
    love.graphics.setFont(mvpFont)
    love.graphics.setColor(0.7, 1, 0.7)
    local offenseLabel = "Offensive:"
    love.graphics.print(offenseLabel, popupX + UIScale.scaleWidth(80), contentY)

    love.graphics.setColor(1, 1, 1)
    local offenseMVPText = "N/A"
    if MatchResultPopup.offensiveMVP then
        offenseMVPText = string.format("%s #%d",
            MatchResultPopup.offensiveMVP.position,
            MatchResultPopup.offensiveMVP.number)
    end
    love.graphics.print(offenseMVPText, popupX + UIScale.scaleWidth(200), contentY)

    contentY = contentY + UIScale.scaleHeight(30)

    -- Defensive MVP
    love.graphics.setColor(1, 0.7, 0.7)
    local defenseLabel = "Defensive:"
    love.graphics.print(defenseLabel, popupX + UIScale.scaleWidth(80), contentY)

    love.graphics.setColor(1, 1, 1)
    local defenseMVPText = "N/A"
    if MatchResultPopup.defensiveMVP then
        defenseMVPText = string.format("%s #%d",
            MatchResultPopup.defensiveMVP.position,
            MatchResultPopup.defensiveMVP.number)
    end
    love.graphics.print(defenseMVPText, popupX + UIScale.scaleWidth(200), contentY)

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
