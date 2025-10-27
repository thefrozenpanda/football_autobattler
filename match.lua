-- match.lua
local PhaseManager = require("phase_manager")

local match = {}

local phaseManager
local font
local smallFont
local matchTime = 60
local timeLeft = matchTime

-- Card visual constants
local CARD_WIDTH = 140
local CARD_HEIGHT = 180
local CARD_PADDING = 20
local PROGRESS_BAR_HEIGHT = 8

function match.load()
    font = love.graphics.newFont(20)
    smallFont = love.graphics.newFont(14)
    phaseManager = PhaseManager:new()
    timeLeft = matchTime
end

function match.update(dt)
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
    match.drawTeamCards(phaseManager:getActivePlayerCards(), "left", "Player")

    -- Draw AI cards (right side)
    match.drawTeamCards(phaseManager:getActiveAICards(), "right", "AI")
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
    love.graphics.printf("PWR: " .. card.power, x, y + 45, CARD_WIDTH, "center")
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

function match.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

return match
