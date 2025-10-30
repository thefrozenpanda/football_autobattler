--- team_naming.lua
--- Team Naming Screen
---
--- Allows the player to enter a custom team name after coach selection.
--- Appears after coach selection and before season begins.
---
--- Dependencies: None
--- Used by: main.lua
--- LÖVE Callbacks: love.textinput, love.keypressed

local TeamNaming = {}

-- State
TeamNaming.teamName = ""
TeamNaming.maxLength = 30
TeamNaming.cursorVisible = true
TeamNaming.cursorTimer = 0
TeamNaming.selectedCoach = nil
TeamNaming.confirmRequested = false

-- UI configuration
local SCREEN_WIDTH = 1600
local SCREEN_HEIGHT = 900
local TITLE_Y = 150
local INPUT_BOX_Y = 350
local INPUT_BOX_WIDTH = 600
local INPUT_BOX_HEIGHT = 60
local BUTTON_Y = 500
local BUTTON_WIDTH = 200
local BUTTON_HEIGHT = 50

--- Initializes the team naming screen
--- @param coach table The selected coach data
function TeamNaming.load(coach)
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
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(48))
    local titleText = "Name Your Team"
    local titleWidth = love.graphics.getFont():getWidth(titleText)
    love.graphics.print(titleText, (SCREEN_WIDTH - titleWidth) / 2, TITLE_Y)

    -- Coach selection reminder
    love.graphics.setFont(love.graphics.newFont(24))
    local coachText = string.format("Coach: %s", TeamNaming.selectedCoach and TeamNaming.selectedCoach.name or "Unknown")
    local coachWidth = love.graphics.getFont():getWidth(coachText)
    love.graphics.setColor(0.7, 0.7, 0.8)
    love.graphics.print(coachText, (SCREEN_WIDTH - coachWidth) / 2, TITLE_Y + 80)

    -- Input box
    local inputBoxX = (SCREEN_WIDTH - INPUT_BOX_WIDTH) / 2
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", inputBoxX, INPUT_BOX_Y, INPUT_BOX_WIDTH, INPUT_BOX_HEIGHT)

    -- Input box border
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", inputBoxX, INPUT_BOX_Y, INPUT_BOX_WIDTH, INPUT_BOX_HEIGHT)

    -- Team name text
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(32))
    local displayText = TeamNaming.teamName
    if #displayText == 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        displayText = "Enter team name..."
    end
    love.graphics.print(displayText, inputBoxX + 20, INPUT_BOX_Y + 15)

    -- Cursor
    if TeamNaming.cursorVisible and #TeamNaming.teamName < TeamNaming.maxLength then
        love.graphics.setColor(1, 1, 1)
        local textWidth = love.graphics.getFont():getWidth(TeamNaming.teamName)
        love.graphics.rectangle("fill", inputBoxX + 20 + textWidth + 5, INPUT_BOX_Y + 15, 3, 32)
    end

    -- Character count
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(0.6, 0.6, 0.7)
    local countText = string.format("%d / %d", #TeamNaming.teamName, TeamNaming.maxLength)
    love.graphics.print(countText, inputBoxX + INPUT_BOX_WIDTH - 80, INPUT_BOX_Y + INPUT_BOX_HEIGHT + 10)

    -- Confirm button
    local buttonX = (SCREEN_WIDTH - BUTTON_WIDTH) / 2
    local mx, my = love.mouse.getPosition()
    local hoveringButton = mx >= buttonX and mx <= buttonX + BUTTON_WIDTH and
                           my >= BUTTON_Y and my <= BUTTON_Y + BUTTON_HEIGHT

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

    love.graphics.rectangle("fill", buttonX, BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT)

    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", buttonX, BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT)

    -- Button text
    love.graphics.setFont(love.graphics.newFont(28))
    if buttonEnabled then
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
    end
    local buttonText = "Start Season"
    local buttonTextWidth = love.graphics.getFont():getWidth(buttonText)
    love.graphics.print(buttonText, buttonX + (BUTTON_WIDTH - buttonTextWidth) / 2, BUTTON_Y + 10)

    -- Instructions
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(0.7, 0.7, 0.8)
    local instructText = "Type your team name and press Enter or click Start Season"
    local instructWidth = love.graphics.getFont():getWidth(instructText)
    love.graphics.print(instructText, (SCREEN_WIDTH - instructWidth) / 2, BUTTON_Y + 100)
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
    local buttonX = (SCREEN_WIDTH - BUTTON_WIDTH) / 2
    if x >= buttonX and x <= buttonX + BUTTON_WIDTH and
       y >= BUTTON_Y and y <= BUTTON_Y + BUTTON_HEIGHT then
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
