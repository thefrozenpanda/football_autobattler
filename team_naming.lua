--- team_naming.lua
--- Team Naming Screen
---
--- Allows the player to enter a custom team name after coach selection.
--- Appears after coach selection and before season begins.
---
--- Dependencies: ui_scale.lua
--- Used by: main.lua
--- LÖVE Callbacks: love.textinput, love.keypressed

local TeamNaming = {}
local UIScale = require("ui_scale")

-- State
TeamNaming.teamName = ""
TeamNaming.maxLength = 30
TeamNaming.cursorVisible = true
TeamNaming.cursorTimer = 0
TeamNaming.selectedCoach = nil
TeamNaming.confirmRequested = false

-- UI configuration (base values for 1600x900)
local TITLE_Y = 150
local INPUT_BOX_Y = 350
local INPUT_BOX_WIDTH = 600
local INPUT_BOX_HEIGHT = 60
local BUTTON_Y = 500
local BUTTON_WIDTH = 200
local BUTTON_HEIGHT = 50

-- Fonts
local titleFont
local coachFont
local inputFont
local countFont
local buttonFont
local instructFont

--- Initializes the team naming screen
--- @param coach table The selected coach data
function TeamNaming.load(coach)
    -- Update UI scale
    UIScale.update()

    -- Create fonts
    titleFont = love.graphics.newFont(UIScale.scaleFontSize(48))
    coachFont = love.graphics.newFont(UIScale.scaleFontSize(24))
    inputFont = love.graphics.newFont(UIScale.scaleFontSize(32))
    countFont = love.graphics.newFont(UIScale.scaleFontSize(18))
    buttonFont = love.graphics.newFont(UIScale.scaleFontSize(28))
    instructFont = love.graphics.newFont(UIScale.scaleFontSize(20))

    TeamNaming.selectedCoach = coach
    TeamNaming.teamName = ""
    TeamNaming.confirmRequested = false
    TeamNaming.cursorVisible = true
    TeamNaming.cursorTimer = 0
end

--- LÖVE Callback: Update Logic
--- @param dt number Delta time in seconds
function TeamNaming.update(dt)
    -- Animate cursor blink
    TeamNaming.cursorTimer = TeamNaming.cursorTimer + dt
    if TeamNaming.cursorTimer >= 0.5 then
        TeamNaming.cursorVisible = not TeamNaming.cursorVisible
        TeamNaming.cursorTimer = 0
    end
end

--- LÖVE Callback: Draw UI
function TeamNaming.draw()
    love.graphics.setColor(0.1, 0.1, 0.15)
    love.graphics.rectangle("fill", 0, 0, UIScale.getWidth(), UIScale.getHeight())

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(titleFont)
    local titleText = "Name Your Team"
    local titleWidth = titleFont:getWidth(titleText)
    love.graphics.print(titleText, (UIScale.getWidth() - titleWidth) / 2, UIScale.scaleY(TITLE_Y))

    -- Coach selection reminder
    love.graphics.setFont(coachFont)
    local coachText = string.format("Coach: %s", TeamNaming.selectedCoach and TeamNaming.selectedCoach.name or "Unknown")
    local coachWidth = coachFont:getWidth(coachText)
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.print(coachText, (UIScale.getWidth() - coachWidth) / 2, UIScale.scaleY(TITLE_Y + 80))

    -- Input box
    local scaledInputBoxWidth = UIScale.scaleWidth(INPUT_BOX_WIDTH)
    local scaledInputBoxHeight = UIScale.scaleHeight(INPUT_BOX_HEIGHT)
    local inputBoxX = (UIScale.getWidth() - scaledInputBoxWidth) / 2
    local inputBoxY = UIScale.scaleY(INPUT_BOX_Y)

    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", inputBoxX, inputBoxY, scaledInputBoxWidth, scaledInputBoxHeight)

    -- Input box border
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.setLineWidth(UIScale.scaleUniform(3))
    love.graphics.rectangle("line", inputBoxX, inputBoxY, scaledInputBoxWidth, scaledInputBoxHeight)

    -- Team name text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(inputFont)
    local displayText = TeamNaming.teamName
    if #displayText == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        displayText = "Enter team name..."
    end
    love.graphics.print(displayText, inputBoxX + UIScale.scaleWidth(20), inputBoxY + UIScale.scaleHeight(15))

    -- Cursor
    if TeamNaming.cursorVisible and #TeamNaming.teamName < TeamNaming.maxLength then
        love.graphics.setColor(1, 1, 1)
        local textWidth = inputFont:getWidth(TeamNaming.teamName)
        love.graphics.rectangle("fill", inputBoxX + UIScale.scaleWidth(20) + textWidth + UIScale.scaleWidth(5), inputBoxY + UIScale.scaleHeight(15), UIScale.scaleWidth(3), UIScale.scaleHeight(32))
    end

    -- Character count
    love.graphics.setFont(countFont)
    love.graphics.setColor(0.6, 0.6, 0.7)
    local countText = string.format("%d / %d", #TeamNaming.teamName, TeamNaming.maxLength)
    love.graphics.print(countText, inputBoxX + scaledInputBoxWidth - UIScale.scaleWidth(80), inputBoxY + scaledInputBoxHeight + UIScale.scaleHeight(10))

    -- Confirm button
    local scaledButtonWidth = UIScale.scaleWidth(BUTTON_WIDTH)
    local scaledButtonHeight = UIScale.scaleHeight(BUTTON_HEIGHT)
    local scaledButtonY = UIScale.scaleY(BUTTON_Y)
    local buttonX = (UIScale.getWidth() - scaledButtonWidth) / 2

    local mx, my = love.mouse.getPosition()
    local hoveringButton = mx >= buttonX and mx <= buttonX + scaledButtonWidth and
                           my >= scaledButtonY and my <= scaledButtonY + scaledButtonHeight

    -- Button disabled if name is empty
    local buttonEnabled = #TeamNaming.teamName > 0

    if buttonEnabled then
        if hoveringButton then
            love.graphics.setColor(0.3, 0.6, 0.3)
        else
            love.graphics.setColor(0.2, 0.5, 0.2)
        end
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
    end

    love.graphics.rectangle("fill", buttonX, scaledButtonY, scaledButtonWidth, scaledButtonHeight)

    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(UIScale.scaleUniform(2))
    love.graphics.rectangle("line", buttonX, scaledButtonY, scaledButtonWidth, scaledButtonHeight)

    -- Button text
    love.graphics.setFont(buttonFont)
    if buttonEnabled then
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
    end
    local buttonText = "Start Season"
    local buttonTextWidth = buttonFont:getWidth(buttonText)
    love.graphics.print(buttonText, buttonX + (scaledButtonWidth - buttonTextWidth) / 2, scaledButtonY + UIScale.scaleHeight(10))

    -- Instructions
    love.graphics.setFont(instructFont)
    love.graphics.setColor(0.7, 0.7, 0.8)
    local instructText = "Type your team name and press Enter or click Start Season"
    local instructWidth = instructFont:getWidth(instructText)
    love.graphics.print(instructText, (UIScale.getWidth() - instructWidth) / 2, scaledButtonY + UIScale.scaleHeight(100))
end

--- LÖVE Callback: Text Input
--- @param text string The input text
function TeamNaming.textinput(text)
    -- Only accept alphanumeric and spaces
    if text:match("^[%w%s]$") and #TeamNaming.teamName < TeamNaming.maxLength then
        TeamNaming.teamName = TeamNaming.teamName .. text
        TeamNaming.cursorVisible = true
        TeamNaming.cursorTimer = 0
    end
end

--- LÖVE Callback: Key Pressed
--- @param key string The key pressed
function TeamNaming.keypressed(key)
    if key == "backspace" then
        -- Remove last character
        TeamNaming.teamName = TeamNaming.teamName:sub(1, -2)
        TeamNaming.cursorVisible = true
        TeamNaming.cursorTimer = 0
    elseif key == "return" or key == "kpenter" then
        -- Confirm team name
        if #TeamNaming.teamName > 0 then
            TeamNaming.confirmRequested = true
        end
    end
end

--- LÖVE Callback: Mouse Pressed
--- @param x number Mouse X position
--- @param y number Mouse Y position
--- @param button number Mouse button (1 = left, 2 = right, 3 = middle)
function TeamNaming.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    -- Check if clicked on confirm button
    local scaledButtonWidth = UIScale.scaleWidth(BUTTON_WIDTH)
    local scaledButtonHeight = UIScale.scaleHeight(BUTTON_HEIGHT)
    local scaledButtonY = UIScale.scaleY(BUTTON_Y)
    local buttonX = (UIScale.getWidth() - scaledButtonWidth) / 2

    if x >= buttonX and x <= buttonX + scaledButtonWidth and
       y >= scaledButtonY and y <= scaledButtonY + scaledButtonHeight then
        if #TeamNaming.teamName > 0 then
            TeamNaming.confirmRequested = true
        end
    end
end

--- Gets the entered team name
--- @return string The team name
function TeamNaming.getTeamName()
    return TeamNaming.teamName
end

--- Checks if confirmation was requested
--- @return boolean True if user confirmed
function TeamNaming.isConfirmed()
    return TeamNaming.confirmRequested
end

return TeamNaming
