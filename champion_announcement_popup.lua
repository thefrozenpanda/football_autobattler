--- champion_announcement_popup.lua
--- Champion Announcement Popup
---
--- Displays the championship game result after simulating playoffs.
--- Shows winner and final score with a "Continue" button.
---
--- Dependencies: ui_scale.lua
--- Used by: main.lua
--- LÖVE Callbacks: love.draw, love.mousepressed

local ChampionAnnouncementPopup = {}
local UIScale = require("ui_scale")

ChampionAnnouncementPopup.active = false
ChampionAnnouncementPopup.championTeam = nil
ChampionAnnouncementPopup.runnerUpTeam = nil
ChampionAnnouncementPopup.championScore = 0
ChampionAnnouncementPopup.runnerUpScore = 0
ChampionAnnouncementPopup.continueRequested = false

-- UI configuration (base values for 1600x900)
local POPUP_WIDTH = 600
local POPUP_HEIGHT = 300
local BUTTON_WIDTH = 200
local BUTTON_HEIGHT = 50

-- Fonts
local titleFont
local scoreFont
local buttonFont

--- Initializes the champion announcement popup
function ChampionAnnouncementPopup.init()
    UIScale.update()
    titleFont = love.graphics.newFont(UIScale.scaleFontSize(32))
    scoreFont = love.graphics.newFont(UIScale.scaleFontSize(24))
    buttonFont = love.graphics.newFont(UIScale.scaleFontSize(22))
end

--- Shows the champion announcement popup
--- @param champion table The championship winning team
--- @param runnerUp table The runner-up team
--- @param championScore number Champion's score
--- @param runnerUpScore number Runner-up's score
function ChampionAnnouncementPopup.show(champion, runnerUp, championScore, runnerUpScore)
    ChampionAnnouncementPopup.active = true
    ChampionAnnouncementPopup.championTeam = champion
    ChampionAnnouncementPopup.runnerUpTeam = runnerUp
    ChampionAnnouncementPopup.championScore = championScore
    ChampionAnnouncementPopup.runnerUpScore = runnerUpScore
    ChampionAnnouncementPopup.continueRequested = false
end

--- Hides the champion announcement popup
function ChampionAnnouncementPopup.hide()
    ChampionAnnouncementPopup.active = false
    ChampionAnnouncementPopup.continueRequested = false
end

--- Checks if popup is active
--- @return boolean True if popup is showing
function ChampionAnnouncementPopup.isActive()
    return ChampionAnnouncementPopup.active
end

--- Checks if continue was requested
--- @return boolean True if button clicked
function ChampionAnnouncementPopup.isContinueRequested()
    return ChampionAnnouncementPopup.continueRequested
end

--- LÖVE Callback: Draw UI
function ChampionAnnouncementPopup.draw()
    if not ChampionAnnouncementPopup.active then
        return
    end

    -- Initialize fonts if needed
    if not titleFont then
        ChampionAnnouncementPopup.init()
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
    love.graphics.setColor(1, 0.84, 0)  -- Gold border for champion
    love.graphics.setLineWidth(UIScale.scaleUniform(4))
    love.graphics.rectangle("line", popupX, popupY, scaledPopupWidth, scaledPopupHeight)

    local yOffset = popupY + UIScale.scaleHeight(40)

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 0.84, 0)  -- Gold
    local titleText = "Championship Results"
    local titleWidth = titleFont:getWidth(titleText)
    love.graphics.print(titleText, popupX + (scaledPopupWidth - titleWidth) / 2, yOffset)

    yOffset = yOffset + UIScale.scaleHeight(60)

    -- Champion announcement
    love.graphics.setFont(scoreFont)
    love.graphics.setColor(1, 1, 1)
    local championName = ChampionAnnouncementPopup.championTeam and ChampionAnnouncementPopup.championTeam.name or "Unknown"
    local runnerUpName = ChampionAnnouncementPopup.runnerUpTeam and ChampionAnnouncementPopup.runnerUpTeam.name or "Unknown"

    local resultText = string.format("%s defeats %s", championName, runnerUpName)
    local resultWidth = scoreFont:getWidth(resultText)
    love.graphics.print(resultText, popupX + (scaledPopupWidth - resultWidth) / 2, yOffset)

    yOffset = yOffset + UIScale.scaleHeight(40)

    -- Score
    love.graphics.setColor(0.8, 0.9, 1)
    local scoreText = string.format("%d - %d", ChampionAnnouncementPopup.championScore, ChampionAnnouncementPopup.runnerUpScore)
    local scoreWidth = scoreFont:getWidth(scoreText)
    love.graphics.print(scoreText, popupX + (scaledPopupWidth - scoreWidth) / 2, yOffset)

    yOffset = yOffset + UIScale.scaleHeight(60)

    -- Continue button
    local scaledButtonWidth = UIScale.scaleWidth(BUTTON_WIDTH)
    local scaledButtonHeight = UIScale.scaleHeight(BUTTON_HEIGHT)
    local buttonX = popupX + (scaledPopupWidth - scaledButtonWidth) / 2
    local buttonY = yOffset

    local mx, my = love.mouse.getPosition()
    local hoveringButton = mx >= buttonX and mx <= buttonX + scaledButtonWidth and
                          my >= buttonY and my <= buttonY + scaledButtonHeight

    -- Button background
    if hoveringButton then
        love.graphics.setColor(0.4, 0.6, 0.8)
    else
        love.graphics.setColor(0.3, 0.5, 0.7)
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
function ChampionAnnouncementPopup.mousepressed(x, y, button)
    if not ChampionAnnouncementPopup.active or button ~= 1 then
        return
    end

    -- Initialize fonts if needed
    if not titleFont then
        ChampionAnnouncementPopup.init()
    end

    -- Check if continue button was clicked
    local scaledPopupWidth = UIScale.scaleWidth(POPUP_WIDTH)
    local scaledButtonWidth = UIScale.scaleWidth(BUTTON_WIDTH)
    local scaledButtonHeight = UIScale.scaleHeight(BUTTON_HEIGHT)

    local popupX = UIScale.centerX(scaledPopupWidth)
    local buttonX = popupX + (scaledPopupWidth - scaledButtonWidth) / 2
    local buttonY = UIScale.centerY(UIScale.scaleHeight(POPUP_HEIGHT)) + UIScale.scaleHeight(220)

    if x >= buttonX and x <= buttonX + scaledButtonWidth and
       y >= buttonY and y <= buttonY + scaledButtonHeight then
        ChampionAnnouncementPopup.continueRequested = true
    end
end

return ChampionAnnouncementPopup
