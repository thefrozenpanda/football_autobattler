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

MatchResultPopup.active = false
MatchResultPopup.playerScore = 0
MatchResultPopup.opponentScore = 0
MatchResultPopup.playerTeamName = ""
MatchResultPopup.opponentTeamName = ""
MatchResultPopup.continueRequested = false

-- UI configuration (base values for 1600x900)
local POPUP_WIDTH = 600
local POPUP_HEIGHT = 350
local BUTTON_WIDTH = 200
local BUTTON_HEIGHT = 50

-- Fonts
local titleFont
local scoreFont
local teamFont
local buttonFont

--- Initializes the match result popup
function MatchResultPopup.init()
    UIScale.update()
    titleFont = love.graphics.newFont(UIScale.scaleFontSize(36))
    scoreFont = love.graphics.newFont(UIScale.scaleFontSize(48))
    teamFont = love.graphics.newFont(UIScale.scaleFontSize(24))
    buttonFont = love.graphics.newFont(UIScale.scaleFontSize(26))
end

--- Shows the match result popup
--- @param playerScore number Player's final score
--- @param opponentScore number Opponent's final score
--- @param playerTeamName string Player's team name
--- @param opponentTeamName string Opponent's team name
function MatchResultPopup.show(playerScore, opponentScore, playerTeamName, opponentTeamName)
    MatchResultPopup.active = true
    MatchResultPopup.playerScore = playerScore
    MatchResultPopup.opponentScore = opponentScore
    MatchResultPopup.playerTeamName = playerTeamName
    MatchResultPopup.opponentTeamName = opponentTeamName
    MatchResultPopup.continueRequested = false
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

    -- Title (Win/Loss/Tie)
    love.graphics.setFont(titleFont)
    local titleText = ""
    local titleColor = {1, 1, 1}

    if MatchResultPopup.playerScore > MatchResultPopup.opponentScore then
        titleText = "Victory!"
        titleColor = {0.3, 1, 0.3}
    elseif MatchResultPopup.playerScore < MatchResultPopup.opponentScore then
        titleText = "Defeat"
        titleColor = {1, 0.3, 0.3}
    else
        titleText = "Tie"
        titleColor = {1, 1, 0.5}
    end

    love.graphics.setColor(titleColor)
    local titleWidth = titleFont:getWidth(titleText)
    love.graphics.print(titleText, popupX + (scaledPopupWidth - titleWidth) / 2, contentY)

    contentY = contentY + UIScale.scaleHeight(70)

    -- Player team and score
    love.graphics.setFont(teamFont)
    love.graphics.setColor(0.8, 0.9, 1)
    local playerTeamWidth = teamFont:getWidth(MatchResultPopup.playerTeamName)
    love.graphics.print(MatchResultPopup.playerTeamName, popupX + (scaledPopupWidth - playerTeamWidth) / 2, contentY)

    contentY = contentY + UIScale.scaleHeight(35)

    love.graphics.setFont(scoreFont)
    love.graphics.setColor(1, 1, 1)
    local playerScoreText = tostring(MatchResultPopup.playerScore)
    local playerScoreWidth = scoreFont:getWidth(playerScoreText)
    love.graphics.print(playerScoreText, popupX + (scaledPopupWidth - playerScoreWidth) / 2, contentY)

    contentY = contentY + UIScale.scaleHeight(60)

    -- Separator
    love.graphics.setFont(teamFont)
    love.graphics.setColor(0.6, 0.6, 0.7)
    local vsText = "vs"
    local vsWidth = teamFont:getWidth(vsText)
    love.graphics.print(vsText, popupX + (scaledPopupWidth - vsWidth) / 2, contentY)

    contentY = contentY + UIScale.scaleHeight(35)

    -- Opponent team and score
    love.graphics.setFont(teamFont)
    love.graphics.setColor(1, 0.8, 0.8)
    local opponentTeamWidth = teamFont:getWidth(MatchResultPopup.opponentTeamName)
    love.graphics.print(MatchResultPopup.opponentTeamName, popupX + (scaledPopupWidth - opponentTeamWidth) / 2, contentY)

    contentY = contentY + UIScale.scaleHeight(35)

    love.graphics.setFont(scoreFont)
    love.graphics.setColor(1, 1, 1)
    local opponentScoreText = tostring(MatchResultPopup.opponentScore)
    local opponentScoreWidth = scoreFont:getWidth(opponentScoreText)
    love.graphics.print(opponentScoreText, popupX + (scaledPopupWidth - opponentScoreWidth) / 2, contentY)

    -- Continue button
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
    local buttonText = "Continue"
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
