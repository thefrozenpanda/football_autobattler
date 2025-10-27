-- match.lua
local PhaseManager = require("phase_manager")

local match = {}

local phaseManager
local font
local titleFont
local smallFont
local menuFont
local matchTime = 30  -- Changed to 30 seconds per design doc
local timeLeft = matchTime

-- Card visual constants
local CARD_WIDTH = 140
local CARD_HEIGHT = 180
local CARD_PADDING = 20
local PROGRESS_BAR_HEIGHT = 8

-- Pause menu constants
local paused = false
local pauseButtonWidth = 300
local pauseButtonHeight = 60
local pauseButtonY = {250, 340}
local pauseMenuOptions = {"Resume", "Quit"}
local selectedPauseOption = 0  -- 0 means no selection

function match.load(playerCoachId, aiCoachId)
    font = love.graphics.newFont(20)
    titleFont = love.graphics.newFont(48)
    smallFont = love.graphics.newFont(14)
    menuFont = love.graphics.newFont(28)
    phaseManager = PhaseManager:new(playerCoachId, aiCoachId)
    timeLeft = matchTime
    paused = false
    selectedPauseOption = 0
end

function match.update(dt)
    -- Don't update game logic if paused
    if paused then
        return
    end

    timeLeft = math.max(0, timeLeft - dt)

    -- Update phase manager (cards and yards)
    phaseManager:update(dt)

    -- Check for phase transitions (TD or turnover)
    phaseManager:checkPhaseEnd()

    if timeLeft <= 0 then
        -- Match over
    end
end

function match.draw()
    love.graphics.clear(0.05, 0.15, 0.1, 1)

    -- Draw UI at top
    match.drawUI()

    -- Draw player cards (left side)
    local playerCoachName = phaseManager:getPlayerCoachName()
    match.drawTeamCards(phaseManager:getActivePlayerCards(), "left", playerCoachName)

    -- Draw AI cards (right side)
    local aiCoachName = phaseManager:getAICoachName()
    match.drawTeamCards(phaseManager:getActiveAICards(), "right", aiCoachName)

    -- Draw pause menu overlay if paused
    if paused then
        match.drawPauseMenu()
    end
end

function match.drawUI()
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)

    -- Phase indicator
    local phaseName = phaseManager:getCurrentPhaseName()
    love.graphics.printf("Phase: " .. phaseName, 0, 20, 800, "center")

    -- Yards and Down
    local yards = math.floor(phaseManager.field.yards)
    local down = phaseManager.field.down
    love.graphics.printf("Yards: " .. yards .. " | Down: " .. down, 0, 50, 800, "center")

    -- Score
    local playerScore = phaseManager.playerScore
    local aiScore = phaseManager.aiScore
    love.graphics.printf("Score - Player: " .. playerScore .. " | AI: " .. aiScore, 0, 80, 800, "center")

    -- Time
    love.graphics.printf(string.format("Time: %.1f", timeLeft), 0, 110, 800, "center")
end

function match.drawTeamCards(cards, side, teamName)
    local startX
    if side == "left" then
        startX = 50
    else
        startX = 800 - 50 - (CARD_WIDTH * 2 + CARD_PADDING)
    end

    local startY = 200

    -- Draw team label
    love.graphics.setFont(smallFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(teamName, startX, startY - 25, CARD_WIDTH * 2 + CARD_PADDING, "center")

    -- Draw cards in 2x2 grid
    for i, card in ipairs(cards) do
        local row = math.floor((i - 1) / 2)
        local col = (i - 1) % 2

        local x = startX + col * (CARD_WIDTH + CARD_PADDING)
        local y = startY + row * (CARD_HEIGHT + CARD_PADDING)

        match.drawCard(card, x, y)
    end
end

function match.drawCard(card, x, y)
    -- Determine border color based on whether card just acted
    local borderColor = {0.3, 0.5, 0.7}  -- Default blue
    local bgColor = {0.15, 0.2, 0.25}    -- Dark background

    if card.justActed then
        -- Invert colors when card acts
        borderColor = {1.0, 0.8, 0.3}  -- Gold/yellow highlight
    end

    -- Draw card background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT, 8, 8)

    -- Draw card border
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT, 8, 8)

    -- Draw position name
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(card.position, x, y + 10, CARD_WIDTH, "center")

    -- Draw stats
    love.graphics.setFont(smallFont)
    love.graphics.printf("PWR: " .. math.floor(card.power), x, y + 45, CARD_WIDTH, "center")
    love.graphics.printf("SPD: " .. string.format("%.1f", card.speed), x, y + 70, CARD_WIDTH, "center")

    -- Draw progress bar
    local progressBarY = y + CARD_HEIGHT - PROGRESS_BAR_HEIGHT - 10
    local progressBarWidth = CARD_WIDTH - 20
    local progressBarX = x + 10

    -- Progress bar background
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", progressBarX, progressBarY, progressBarWidth, PROGRESS_BAR_HEIGHT)

    -- Progress bar fill
    local progress = card:getProgress()
    love.graphics.setColor(0.3, 0.7, 0.3)  -- Green
    love.graphics.rectangle("fill", progressBarX, progressBarY, progressBarWidth * progress, PROGRESS_BAR_HEIGHT)

    -- Progress bar border
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", progressBarX, progressBarY, progressBarWidth, PROGRESS_BAR_HEIGHT)
end

function match.drawPauseMenu()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    -- Draw "PAUSED" title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PAUSED", 0, 100, 800, "center")

    -- Draw menu options
    love.graphics.setFont(menuFont)
    for i, option in ipairs(pauseMenuOptions) do
        local x = (800 - pauseButtonWidth) / 2
        local y = pauseButtonY[i]

        -- Draw button background
        if i == selectedPauseOption then
            love.graphics.setColor(0.3, 0.5, 0.7, 0.8)
        else
            love.graphics.setColor(0.2, 0.3, 0.4, 0.6)
        end
        love.graphics.rectangle("fill", x, y, pauseButtonWidth, pauseButtonHeight, 10, 10)

        -- Draw button border
        if i == selectedPauseOption then
            love.graphics.setColor(0.5, 0.7, 1.0)
            love.graphics.setLineWidth(3)
        else
            love.graphics.setColor(0.4, 0.5, 0.6)
            love.graphics.setLineWidth(2)
        end
        love.graphics.rectangle("line", x, y, pauseButtonWidth, pauseButtonHeight, 10, 10)

        -- Draw button text
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(option, x, y + 15, pauseButtonWidth, "center")
    end
end

function match.keypressed(key)
    if paused then
        -- Handle pause menu input
        if key == "escape" then
            match.resumeGame()
        elseif key == "up" then
            selectedPauseOption = selectedPauseOption - 1
            if selectedPauseOption < 1 then
                selectedPauseOption = #pauseMenuOptions
            end
        elseif key == "down" then
            selectedPauseOption = selectedPauseOption + 1
            if selectedPauseOption > #pauseMenuOptions then
                selectedPauseOption = 1
            end
        elseif key == "return" or key == "space" then
            if selectedPauseOption > 0 then
                match.selectPauseOption(selectedPauseOption)
            end
        end
    else
        -- Handle in-game input
        if key == "escape" then
            match.pauseGame()
        end
    end
end

function match.pauseGame()
    paused = true
    selectedPauseOption = 0
end

function match.resumeGame()
    paused = false
    selectedPauseOption = 0
end

function match.selectPauseOption(option)
    if option == 1 then
        -- Resume
        match.resumeGame()
    elseif option == 2 then
        -- Quit
        love.event.quit()
    end
end

function match.mousepressed(x, y, button)
    if not paused then
        return
    end

    if button == 1 then
        local buttonX = (800 - pauseButtonWidth) / 2
        for i = 1, #pauseMenuOptions do
            local buttonYPos = pauseButtonY[i]
            if x >= buttonX and x <= buttonX + pauseButtonWidth and
               y >= buttonYPos and y <= buttonYPos + pauseButtonHeight then
                match.selectPauseOption(i)
                break
            end
        end
    end
end

function match.mousemoved(x, y)
    if not paused then
        return
    end

    local buttonX = (800 - pauseButtonWidth) / 2
    selectedPauseOption = 0  -- Reset selection
    for i = 1, #pauseMenuOptions do
        local buttonYPos = pauseButtonY[i]
        if x >= buttonX and x <= buttonX + pauseButtonWidth and
           y >= buttonYPos and y <= buttonYPos + pauseButtonHeight then
            selectedPauseOption = i
            break
        end
    end
end

return match
