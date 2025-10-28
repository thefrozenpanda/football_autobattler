-- match.lua
local PhaseManager = require("phase_manager")

local match = {}

local phaseManager
local font
local titleFont
local smallFont
local menuFont
local matchTime = 60  -- Changed to 60 seconds for yard-based system
local timeLeft = matchTime

-- Card visual constants
local CARD_WIDTH = 70
local CARD_HEIGHT = 90
local CARD_PADDING = 8
local PROGRESS_BAR_HEIGHT = 4

-- Pause menu constants
local paused = false
local pauseButtonWidth = 300
local pauseButtonHeight = 60
local pauseButtonY = {250, 340}
local pauseMenuOptions = {"Resume", "Quit"}
local selectedPauseOption = 0

-- Formation positions (relative to team start)
local OFFENSIVE_FORMATION = {
    {x = 0, y = 0},    -- WR (top)
    {x = 40, y = 60},  -- OL
    {x = 0, y = 90},   -- RB
    {x = -20, y = 120}, -- QB
    {x = 0, y = 150},   -- RB
    {x = 40, y = 180},  -- OL
    {x = 40, y = 120},  -- OL (center)
    {x = 40, y = 240},  -- OL
    {x = 40, y = 300},  -- OL
    {x = 20, y = 210},  -- TE
    {x = 0, y = 360}    -- WR (bottom)
}

local DEFENSIVE_FORMATION = {
    {x = 0, y = 0},     -- CB (top)
    {x = -20, y = 40},  -- S
    {x = 40, y = 60},   -- DL
    {x = 40, y = 120},  -- DL
    {x = 40, y = 180},  -- DL
    {x = 40, y = 240},  -- DL
    {x = -20, y = 300}, -- S
    {x = 0, y = 360},   -- CB (bottom)
    {x = 20, y = 100},  -- LB
    {x = 20, y = 180},  -- LB
    {x = 20, y = 260}   -- LB
}

function match.load(playerCoachId, aiCoachId)
    font = love.graphics.newFont(16)
    titleFont = love.graphics.newFont(48)
    smallFont = love.graphics.newFont(10)
    menuFont = love.graphics.newFont(28)
    phaseManager = PhaseManager:new(playerCoachId, aiCoachId)
    timeLeft = matchTime
    paused = false
    selectedPauseOption = 0
end

function match.update(dt)
    if paused then
        return
    end

    timeLeft = math.max(0, timeLeft - dt)

    phaseManager:update(dt)
    phaseManager:checkPhaseEnd()

    if timeLeft <= 0 then
        -- Match over
    end
end

function match.draw()
    love.graphics.clear(0.05, 0.15, 0.1, 1)

    match.drawUI()

    -- Determine which formation to use
    local playerCards = phaseManager:getActivePlayerCards()
    local aiCards = phaseManager:getActiveAICards()

    local playerIsOffense = (phaseManager.currentPhase == "player_offense")
    local playerFormation = playerIsOffense and OFFENSIVE_FORMATION or DEFENSIVE_FORMATION
    local aiFormation = playerIsOffense and DEFENSIVE_FORMATION or OFFENSIVE_FORMATION

    -- Draw cards
    match.drawTeamCards(playerCards, "left", phaseManager:getPlayerCoachName(), playerFormation)
    match.drawTeamCards(aiCards, "right", phaseManager:getAICoachName(), aiFormation)

    if paused then
        match.drawPauseMenu()
    end
end

function match.drawUI()
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)

    -- Phase indicator
    local phaseName = phaseManager:getCurrentPhaseName()
    love.graphics.printf("Phase: " .. phaseName, 0, 10, 800, "center")

    -- Yards display
    local totalYards = math.floor(phaseManager.field.totalYards)
    local yardsNeeded = phaseManager.field.yardsNeeded
    local downYards = math.floor(phaseManager.field.downYards)
    local yardsToFirst = math.floor(phaseManager.field:getYardsToFirstDown())

    love.graphics.printf(
        string.format("Yards: %d/%d | Down: %d  | %d yards to 1st",
        totalYards, yardsNeeded, phaseManager.field.currentDown, yardsToFirst),
        0, 30, 800, "center"
    )

    -- Down timer
    love.graphics.printf(
        string.format("Down Timer: %.1fs", phaseManager.field.downTimer),
        0, 50, 800, "center"
    )

    -- Score
    local playerScore = phaseManager.playerScore
    local aiScore = phaseManager.aiScore
    love.graphics.printf(
        string.format("Score - Player: %d | AI: %d", playerScore, aiScore),
        0, 70, 800, "center"
    )

    -- Game time
    love.graphics.printf(
        string.format("Time: %.1f", timeLeft),
        0, 90, 800, "center"
    )
end

function match.drawTeamCards(cards, side, teamName, formation)
    local startX = (side == "left") and 50 or (800 - 150)
    local startY = 130

    -- Draw team label
    love.graphics.setFont(smallFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(teamName, startX - 20, startY - 20, 150, "center")

    -- Draw cards using formation
    for i, card in ipairs(cards) do
        if formation[i] then
            local pos = formation[i]
            local x = startX + pos.x
            local y = startY + pos.y
            match.drawCard(card, x, y)
        end
    end
end

function match.drawCard(card, x, y)
    -- Determine colors
    local borderColor = {0.3, 0.5, 0.7}
    local bgColor = {0.15, 0.2, 0.25}

    if card.justActed then
        borderColor = {1.0, 0.8, 0.3}
    end

    -- Status effect indicators
    if card.isFrozen then
        bgColor = {0.3, 0.5, 0.8}  -- Blue when frozen
    elseif card.isSlowed then
        bgColor = {0.6, 0.4, 0.2}  -- Brown when slowed
    end

    -- Draw card background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT, 5, 5)

    -- Draw card border
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT, 5, 5)

    -- Draw position name
    love.graphics.setFont(smallFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(card.position, x, y + 5, CARD_WIDTH, "center")

    -- Draw stats based on card type
    local Card = require("card")
    if card.cardType == Card.TYPE.YARD_GENERATOR then
        love.graphics.printf(
            string.format("%.1f yd", card.yardsPerAction),
            x, y + 20, CARD_WIDTH, "center"
        )
    elseif card.cardType == Card.TYPE.BOOSTER then
        love.graphics.printf(
            string.format("+%d%%", card.boostAmount),
            x, y + 20, CARD_WIDTH, "center"
        )
    elseif card.cardType == Card.TYPE.DEFENDER then
        local effectName = card.effectType == Card.EFFECT.SLOW and "SLW" or
                          card.effectType == Card.EFFECT.FREEZE and "FRZ" or "REM"
        love.graphics.printf(effectName, x, y + 20, CARD_WIDTH, "center")
    end

    -- Draw progress bar
    local progressBarY = y + CARD_HEIGHT - PROGRESS_BAR_HEIGHT - 3
    local progressBarWidth = CARD_WIDTH - 10
    local progressBarX = x + 5

    -- Progress bar background
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", progressBarX, progressBarY, progressBarWidth, PROGRESS_BAR_HEIGHT)

    -- Progress bar fill
    local progress = card:getProgress()
    love.graphics.setColor(0.3, 0.7, 0.3)
    love.graphics.rectangle("fill", progressBarX, progressBarY, progressBarWidth * progress, PROGRESS_BAR_HEIGHT)

    -- Progress bar border
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", progressBarX, progressBarY, progressBarWidth, PROGRESS_BAR_HEIGHT)
end

function match.drawPauseMenu()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PAUSED", 0, 100, 800, "center")

    love.graphics.setFont(menuFont)
    for i, option in ipairs(pauseMenuOptions) do
        local x = (800 - pauseButtonWidth) / 2
        local y = pauseButtonY[i]

        if i == selectedPauseOption then
            love.graphics.setColor(0.3, 0.5, 0.7, 0.8)
        else
            love.graphics.setColor(0.2, 0.3, 0.4, 0.6)
        end
        love.graphics.rectangle("fill", x, y, pauseButtonWidth, pauseButtonHeight, 10, 10)

        if i == selectedPauseOption then
            love.graphics.setColor(0.5, 0.7, 1.0)
            love.graphics.setLineWidth(3)
        else
            love.graphics.setColor(0.4, 0.5, 0.6)
            love.graphics.setLineWidth(2)
        end
        love.graphics.rectangle("line", x, y, pauseButtonWidth, pauseButtonHeight, 10, 10)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(option, x, y + 15, pauseButtonWidth, "center")
    end
end

function match.keypressed(key)
    if paused then
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
        match.resumeGame()
    elseif option == 2 then
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
    selectedPauseOption = 0
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
