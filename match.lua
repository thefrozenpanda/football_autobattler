-- match.lua
local PhaseManager = require("phase_manager")
local DebugLogger = require("debug_logger")
local Card = require("card")
local CardManager = require("card_manager")
local FieldState = require("field_state")

local match = {}

local phaseManager
local debugLogger
local font
local titleFont
local smallFont
local menuFont
local matchTime = 60  -- Regulation time: 60 seconds
local overtimeTime = 15  -- Overtime period: 15 seconds
local timeLeft = matchTime
local matchEnded = false
local inOvertime = false
local overtimePeriod = 0  -- 0 = regulation, 1 = first OT, 2 = second OT, etc.
local winnerData = nil  -- Will store winner info and MVP stats

-- Card visual constants
local CARD_WIDTH = 70
local CARD_HEIGHT = 95
local CARD_PADDING = 8
local PROGRESS_BAR_HEIGHT = 5

-- Pause menu constants
local paused = false
local pauseButtonWidth = 300
local pauseButtonHeight = 60
local pauseButtonY = {520, 650}
local pauseMenuOptions = {"Resume", "Quit"}
local selectedPauseOption = 0

-- Winner popup constants
local winnerButtonWidth = 300
local winnerButtonHeight = 60
local winnerButtonY = 700
local winnerButtonHovered = false

-- Formation positions (relative to team start)
-- Based on Offensive.png rotated 90° clockwise (vertical, facing right)
-- Order matches coach.lua: QB, RB, RB, OL, OL, OL, OL, OL, WR, WR, TE
local OFFENSIVE_FORMATION = {
    {x = 30, y = 10},     -- 1. QB (behind line)
    {x = 60, y = 100},    -- 2. RB
    {x = 60, y = 200},    -- 3. RB
    {x = 0, y = 300},     -- 4. OL (line)
    {x = 0, y = 350},     -- 5. OL
    {x = 0, y = 400},     -- 6. OL (center)
    {x = 0, y = 450},     -- 7. OL
    {x = 0, y = 500},     -- 8. OL
    {x = 0, y = 50},      -- 9. WR (wide top)
    {x = 0, y = 750},     -- 10. WR (wide bottom)
    {x = 0, y = 550}      -- 11. TE (near line)
}

-- Based on Defensive.png rotated 90° counter-clockwise (vertical, facing left)
-- Order matches coach.lua: DL, DL, DL, DL, LB, LB, LB, CB, CB, S, S
local DEFENSIVE_FORMATION = {
    {x = 0, y = 300},     -- 1. DL (line)
    {x = 0, y = 350},     -- 2. DL
    {x = 0, y = 450},     -- 3. DL
    {x = 0, y = 500},     -- 4. DL
    {x = 30, y = 350},    -- 5. LB (behind line)
    {x = 30, y = 425},    -- 6. LB
    {x = 30, y = 475},    -- 7. LB
    {x = 0, y = 50},      -- 8. CB (wide top)
    {x = 0, y = 750},     -- 9. CB (wide bottom)
    {x = 60, y = 150},    -- 10. S (deep)
    {x = 60, y = 650}     -- 11. S (deep)
}

function match.load(playerCoachId, aiCoachId)
    -- Initialize debug logger
    debugLogger = DebugLogger:new()

    -- Pass logger to all modules
    Card.logger = debugLogger
    CardManager.logger = debugLogger
    PhaseManager.logger = debugLogger
    FieldState.logger = debugLogger

    debugLogger:log("=== MATCH STARTED ===")
    debugLogger:log("Player Coach: " .. playerCoachId)
    debugLogger:log("AI Coach: " .. aiCoachId)

    font = love.graphics.newFont(20)
    titleFont = love.graphics.newFont(48)
    smallFont = love.graphics.newFont(14)
    menuFont = love.graphics.newFont(28)
    phaseManager = PhaseManager:new(playerCoachId, aiCoachId)
    timeLeft = matchTime
    paused = false
    selectedPauseOption = 0
    matchEnded = false
    inOvertime = false
    overtimePeriod = 0
    winnerData = nil

    debugLogger:log("Match initialization complete")
    debugLogger:log("Down duration: 5.0 seconds")
end

function match.update(dt)
    if paused or matchEnded then
        return
    end

    timeLeft = math.max(0, timeLeft - dt)

    phaseManager:update(dt)
    phaseManager:checkPhaseEnd()

    if timeLeft <= 0 then
        match.handleMatchEnd()
    end
end

function match.handleMatchEnd()
    local playerScore = phaseManager.playerScore
    local aiScore = phaseManager.aiScore

    if playerScore == aiScore then
        -- Tied - go to overtime
        overtimePeriod = overtimePeriod + 1
        inOvertime = true
        timeLeft = overtimeTime

        local overtimeName = match.getOvertimeName(overtimePeriod)
        if debugLogger then
            debugLogger:log("=== " .. overtimeName .. " STARTED ===")
            debugLogger:log("Score tied " .. playerScore .. "-" .. aiScore)
        end
    else
        -- Game over - declare winner
        matchEnded = true
        winnerData = match.calculateWinner()

        if debugLogger then
            debugLogger:log("=== MATCH ENDED ===")
            debugLogger:log("Winner: " .. winnerData.winnerName)
            debugLogger:log("Final Score: Player " .. playerScore .. " - AI " .. aiScore)
        end
    end
end

function match.getOvertimeName(period)
    local names = {"First Overtime", "Second Overtime", "Third Overtime", "Fourth Overtime", "Fifth Overtime"}
    if period <= #names then
        return names[period]
    else
        return period .. "th Overtime"
    end
end

function match.calculateWinner()
    local playerScore = phaseManager.playerScore
    local aiScore = phaseManager.aiScore

    local winner = (playerScore > aiScore) and "player" or "ai"
    local winnerName = (playerScore > aiScore) and "PLAYER" or "AI"
    local winnerCoachName = (winner == "player") and phaseManager:getPlayerCoachName() or phaseManager:getAICoachName()

    -- Get MVP stats
    local offensiveMVP, defensiveMVP
    if winner == "player" then
        offensiveMVP = match.getOffensiveMVP(phaseManager.playerOffense.cards)
        defensiveMVP = match.getDefensiveMVP(phaseManager.playerDefense.cards)
    else
        offensiveMVP = match.getOffensiveMVP(phaseManager.aiOffense.cards)
        defensiveMVP = match.getDefensiveMVP(phaseManager.aiDefense.cards)
    end

    return {
        winner = winner,
        winnerName = winnerName,
        winnerCoachName = winnerCoachName,
        playerScore = playerScore,
        aiScore = aiScore,
        offensiveMVP = offensiveMVP,
        defensiveMVP = defensiveMVP
    }
end

function match.getOffensiveMVP(cards)
    local bestCard = nil
    local bestYards = 0

    for _, card in ipairs(cards) do
        if card.yardsGained > bestYards then
            bestYards = card.yardsGained
            bestCard = card
        end
    end

    if bestCard then
        return {
            position = bestCard.position,
            yards = string.format("%.1f", bestCard.yardsGained),
            touchdowns = bestCard.touchdownsScored
        }
    end
    return {position = "N/A", yards = "0.0", touchdowns = 0}
end

function match.getDefensiveMVP(cards)
    local bestCard = nil
    local bestScore = 0

    for _, card in ipairs(cards) do
        -- Score defensive impact: slows * 1 + freezes * 2 + yards reduced * 0.5
        local score = card.timesSlowed + (card.timesFroze * 2) + (card.yardsReduced * 0.5)
        if score > bestScore then
            bestScore = score
            bestCard = card
        end
    end

    if bestCard then
        return {
            position = bestCard.position,
            slows = bestCard.timesSlowed,
            freezes = bestCard.timesFroze,
            yardsReduced = string.format("%.1f", bestCard.yardsReduced)
        }
    end
    return {position = "N/A", slows = 0, freezes = 0, yardsReduced = "0.0"}
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

    if matchEnded and winnerData then
        match.drawWinnerPopup()
    end
end

function match.drawUI()
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)

    -- Phase indicator
    local phaseName = phaseManager:getCurrentPhaseName()
    love.graphics.printf("Phase: " .. phaseName, 0, 15, 1600, "center")

    -- Yards display
    local totalYards = math.floor(phaseManager.field.totalYards)
    local yardsNeeded = phaseManager.field.yardsNeeded
    local downYards = math.floor(phaseManager.field.downYards)
    local yardsToFirst = math.floor(phaseManager.field:getYardsToFirstDown())

    love.graphics.printf(
        string.format("Yards: %d/%d | Down: %d  | %d yards to 1st",
        totalYards, yardsNeeded, phaseManager.field.currentDown, yardsToFirst),
        0, 45, 1600, "center"
    )

    -- Down timer
    love.graphics.printf(
        string.format("Down Timer: %.1fs", phaseManager.field.downTimer),
        0, 75, 1600, "center"
    )

    -- Score
    local playerScore = phaseManager.playerScore
    local aiScore = phaseManager.aiScore
    love.graphics.printf(
        string.format("Score - Player: %d | AI: %d", playerScore, aiScore),
        0, 105, 1600, "center"
    )

    -- Game time with overtime indicator
    local timeDisplay = string.format("Time: %.1f", timeLeft)
    if inOvertime then
        local overtimeName = match.getOvertimeName(overtimePeriod)
        love.graphics.setColor(1, 0.8, 0)  -- Yellow/gold color for overtime
        love.graphics.printf(overtimeName, 0, 135, 1600, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(timeDisplay, 0, 165, 1600, "center")
    else
        love.graphics.printf(timeDisplay, 0, 135, 1600, "center")
    end
end

function match.drawTeamCards(cards, side, teamName, formation)
    local startX = (side == "left") and 150 or (1600 - 500)
    local startY = 180

    -- Draw team label
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(teamName, startX - 50, startY - 30, 400, "center")

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
    love.graphics.rectangle("fill", 0, 0, 1600, 900)

    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PAUSED", 0, 300, 1600, "center")

    love.graphics.setFont(menuFont)
    for i, option in ipairs(pauseMenuOptions) do
        local x = (1600 - pauseButtonWidth) / 2
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

function match.drawWinnerPopup()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, 1600, 900)

    -- Popup background
    local popupWidth = 700
    local popupHeight = 550
    local popupX = (1600 - popupWidth) / 2
    local popupY = (900 - popupHeight) / 2

    love.graphics.setColor(0.15, 0.2, 0.25)
    love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight, 15, 15)
    love.graphics.setColor(0.4, 0.5, 0.6)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", popupX, popupY, popupWidth, popupHeight, 15, 15)

    -- Winner title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.printf(winnerData.winnerName .. " WINS!", 0, popupY + 30, 1600, "center")

    -- Coach name
    love.graphics.setFont(menuFont)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf(winnerData.winnerCoachName, 0, popupY + 90, 1600, "center")

    -- Final score
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        string.format("Final Score:  Player %d - %d AI", winnerData.playerScore, winnerData.aiScore),
        0, popupY + 135, 1600, "center"
    )

    -- MVP Section
    love.graphics.setFont(menuFont)
    love.graphics.setColor(0.9, 0.6, 0.3)
    love.graphics.printf("Players of the Game", 0, popupY + 185, 1600, "center")

    -- Offensive MVP
    love.graphics.setFont(font)
    love.graphics.setColor(0.3, 0.8, 0.3)
    love.graphics.printf("Offensive Player:", popupX + 50, popupY + 235, popupWidth - 100, "left")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        string.format("%s - %.1f yards, %d TDs",
            winnerData.offensiveMVP.position,
            tonumber(winnerData.offensiveMVP.yards),
            winnerData.offensiveMVP.touchdowns),
        popupX + 50, popupY + 265, popupWidth - 100, "left"
    )

    -- Defensive MVP
    love.graphics.setColor(0.3, 0.6, 0.9)
    love.graphics.printf("Defensive Player:", popupX + 50, popupY + 315, popupWidth - 100, "left")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        string.format("%s - %d slows, %d freezes, %.1f yards reduced",
            winnerData.defensiveMVP.position,
            winnerData.defensiveMVP.slows,
            winnerData.defensiveMVP.freezes,
            tonumber(winnerData.defensiveMVP.yardsReduced)),
        popupX + 50, popupY + 345, popupWidth - 100, "left"
    )

    -- Return to Menu button
    local buttonX = (1600 - winnerButtonWidth) / 2
    local buttonY = popupY + popupHeight - 90

    if winnerButtonHovered then
        love.graphics.setColor(0.3, 0.5, 0.7, 0.9)
    else
        love.graphics.setColor(0.2, 0.3, 0.4, 0.7)
    end
    love.graphics.rectangle("fill", buttonX, buttonY, winnerButtonWidth, winnerButtonHeight, 10, 10)

    if winnerButtonHovered then
        love.graphics.setColor(0.5, 0.7, 1.0)
        love.graphics.setLineWidth(3)
    else
        love.graphics.setColor(0.4, 0.5, 0.6)
        love.graphics.setLineWidth(2)
    end
    love.graphics.rectangle("line", buttonX, buttonY, winnerButtonWidth, winnerButtonHeight, 10, 10)

    love.graphics.setFont(menuFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Return to Menu", buttonX, buttonY + 15, winnerButtonWidth, "center")
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
    if button == 1 then
        -- Winner popup button
        if matchEnded and winnerData then
            local popupHeight = 550
            local popupY = (900 - popupHeight) / 2
            local buttonX = (1600 - winnerButtonWidth) / 2
            local buttonY = popupY + popupHeight - 90

            if x >= buttonX and x <= buttonX + winnerButtonWidth and
               y >= buttonY and y <= buttonY + winnerButtonHeight then
                match.returnToMenu()
                return
            end
        end

        -- Pause menu buttons
        if paused then
            local buttonX = (1600 - pauseButtonWidth) / 2
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
end

function match.mousemoved(x, y)
    -- Winner popup button hover
    if matchEnded and winnerData then
        local popupHeight = 550
        local popupY = (900 - popupHeight) / 2
        local buttonX = (1600 - winnerButtonWidth) / 2
        local buttonY = popupY + popupHeight - 90

        winnerButtonHovered = (x >= buttonX and x <= buttonX + winnerButtonWidth and
                               y >= buttonY and y <= buttonY + winnerButtonHeight)
        return
    end

    -- Pause menu button hover
    if paused then
        local buttonX = (1600 - pauseButtonWidth) / 2
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
end

function match.returnToMenu()
    -- Set flag to return to menu (main.lua will handle transition)
    match.shouldReturnToMenu = true
end

return match
