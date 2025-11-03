-- match.lua
local PhaseManager = require("phase_manager")
local DebugLogger = require("debug_logger")
local Card = require("card")
local CardManager = require("card_manager")
local FieldState = require("field_state")
local UIScale = require("ui_scale")
local flux = require("lib.flux")

local match = {}

local phaseManager
local debugLogger
local font
local titleFont
local smallFont
local menuFont
local cardPositionFont
local cardStatsFont
local cardNumberFont
local cardUpgradeFont
local matchTime = 60  -- Regulation time: 60 seconds
local overtimeTime = 15  -- Overtime period: 15 seconds
local timeLeft = matchTime
local matchEnded = false
local inOvertime = false
local overtimePeriod = 0  -- 0 = regulation, 1 = first OT, 2 = second OT, etc.
local winnerData = nil  -- Will store winner info and MVP stats

-- Team and coach information
local playerTeamName = ""
local aiTeamName = ""
local playerCoachName = ""
local aiCoachName = ""

-- Card visual constants
local CARD_WIDTH = 60
local CARD_HEIGHT = 60
local CARD_PADDING = 8
local PROGRESS_BAR_HEIGHT = 5

-- Pause menu constants
local paused = false
local pauseButtonWidth = 300
local pauseButtonHeight = 60
local pauseButtonY = {450, 560, 670}
local pauseMenuOptions = {"Resume", "Options", "Quit"}
local selectedPauseOption = 0
match.optionsRequested = false  -- Flag set when player clicks "Options" from pause menu

-- Pause menu animation
local pauseMenuOffset = {y = 0}

-- Winner popup constants
local winnerButtonWidth = 300
local winnerButtonHeight = 60
local winnerButtonY = 700
local winnerButtonHovered = false

-- Card dimensions (calculated dynamically to fit 3x10 grid with 5px spacing)
-- Grid area: ~300px wide x ~700px tall
-- With 5px spacing: (300 - 10) / 3 = 96.67px per column, (700 - 45) / 10 = 65.5px per row
local CARD_WIDTH = 60   -- Reduced to fit better with spacing
local CARD_HEIGHT = 60  -- Reduced to fit better with spacing

-- Formation positions (relative to team start)
-- Grid: 3 columns (A, B, C) x 10 rows (1-10)
-- Column spacing: CARD_WIDTH + 5px, Row spacing: CARD_HEIGHT + 5px
-- Order matches coach.lua: QB, RB, RB, OL, OL, OL, OL, OL, WR, WR, TE
local OFFENSIVE_FORMATION = {
    {x = 65, y = 390},    -- 1. QB (B6)
    {x = 0, y = 325},     -- 2. RB (A5)
    {x = 0, y = 455},     -- 3. RB (A7)
    {x = 130, y = 260},   -- 4. OL (C4)
    {x = 130, y = 325},   -- 5. OL (C5)
    {x = 130, y = 390},   -- 6. OL (C6)
    {x = 130, y = 455},   -- 7. OL (C7)
    {x = 130, y = 520},   -- 8. OL (C8)
    {x = 130, y = 65},    -- 9. WR (C1)
    {x = 130, y = 650},   -- 10. WR (C10)
    {x = 65, y = 195}     -- 11. TE (B3)
}

-- Defensive formation (for AI when defending - right side)
-- Grid: 3 columns (A, B, C) x 10 rows (1-10)
-- Order matches coach.lua: DL, DL, DL, DL, LB, LB, LB, CB, CB, S, S
local DEFENSIVE_FORMATION = {
    {x = 0, y = 260},     -- 1. DL (A4)
    {x = 0, y = 325},     -- 2. DL (A5)
    {x = 0, y = 390},     -- 3. DL (A6)
    {x = 0, y = 455},     -- 4. DL (A7)
    {x = 65, y = 260},    -- 5. LB (B4)
    {x = 65, y = 390},    -- 6. LB (B6)
    {x = 65, y = 520},    -- 7. LB (B8)
    {x = 0, y = 65},      -- 8. CB (A1)
    {x = 0, y = 650},     -- 9. CB (A10)
    {x = 130, y = 195},   -- 10. S (C3)
    {x = 130, y = 585}    -- 11. S (C9)
}

-- Mirrored offensive formation (for AI when attacking - flipped horizontally)
local OFFENSIVE_FORMATION_MIRRORED = {
    {x = 65, y = 390},    -- 1. QB (B6)
    {x = 130, y = 325},   -- 2. RB (C5 mirrored from A5)
    {x = 130, y = 455},   -- 3. RB (C7 mirrored from A7)
    {x = 0, y = 260},     -- 4. OL (A4 mirrored from C4)
    {x = 0, y = 325},     -- 5. OL (A5 mirrored from C5)
    {x = 0, y = 390},     -- 6. OL (A6 mirrored from C6)
    {x = 0, y = 455},     -- 7. OL (A7 mirrored from C7)
    {x = 0, y = 520},     -- 8. OL (A8 mirrored from C8)
    {x = 0, y = 65},      -- 9. WR (A1 mirrored from C1)
    {x = 0, y = 650},     -- 10. WR (A10 mirrored from C10)
    {x = 65, y = 195}     -- 11. TE (B3)
}

-- Mirrored defensive formation (for player when defending - flipped horizontally)
local DEFENSIVE_FORMATION_MIRRORED = {
    {x = 130, y = 260},   -- 1. DL (C4 mirrored from A4)
    {x = 130, y = 325},   -- 2. DL (C5 mirrored from A5)
    {x = 130, y = 390},   -- 3. DL (C6 mirrored from A6)
    {x = 130, y = 455},   -- 4. DL (C7 mirrored from A7)
    {x = 65, y = 260},    -- 5. LB (B4)
    {x = 65, y = 390},    -- 6. LB (B6)
    {x = 65, y = 520},    -- 7. LB (B8)
    {x = 130, y = 65},    -- 8. CB (C1 mirrored from A1)
    {x = 130, y = 650},   -- 9. CB (C10 mirrored from A10)
    {x = 0, y = 195},     -- 10. S (A3 mirrored from C3)
    {x = 0, y = 585}      -- 11. S (A9 mirrored from C9)
}

function match.load(playerCoachId, aiCoachId, playerTeam, aiTeam)
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

    -- Update UI scale
    UIScale.update()

    -- Store team and coach names
    local Coach = require("coach")
    playerTeamName = playerTeam or "Player"
    aiTeamName = aiTeam or "Opponent"
    playerCoachName = Coach.getById(playerCoachId).name
    aiCoachName = Coach.getById(aiCoachId).name

    -- Initialize scaled fonts
    font = love.graphics.newFont(UIScale.scaleFontSize(20))
    titleFont = love.graphics.newFont(UIScale.scaleFontSize(48))
    smallFont = love.graphics.newFont(UIScale.scaleFontSize(14))
    menuFont = love.graphics.newFont(UIScale.scaleFontSize(28))
    cardPositionFont = love.graphics.newFont(UIScale.scaleFontSize(12))
    cardStatsFont = love.graphics.newFont(UIScale.scaleFontSize(11))
    cardNumberFont = love.graphics.newFont(UIScale.scaleFontSize(20))
    cardUpgradeFont = love.graphics.newFont(UIScale.scaleFontSize(13))
    phaseManager = PhaseManager:new(playerCoachId, aiCoachId)
    timeLeft = matchTime
    paused = false
    selectedPauseOption = 0
    matchEnded = false
    inOvertime = false
    overtimePeriod = 0
    winnerData = nil
    match.shouldReturnToMenu = false  -- Reset flag for new match
    match.optionsRequested = false  -- Reset options flag

    debugLogger:log("Match initialization complete")
    debugLogger:log("Down duration: 3.0 seconds")
end

function match.update(dt)
    if paused or matchEnded then
        return
    end

    timeLeft = math.max(0, timeLeft - dt)

    phaseManager:update(dt)
    phaseManager:checkPhaseEnd()

    -- In overtime, end game immediately if anyone scores
    if inOvertime and phaseManager.playerScore ~= phaseManager.aiScore then
        matchEnded = true
        winnerData = match.calculateWinner()

        if debugLogger then
            debugLogger:log("=== OVERTIME ENDED - SUDDEN DEATH ===")
            debugLogger:log("Winner: " .. winnerData.winnerName)
            debugLogger:log("Final Score: Player " .. phaseManager.playerScore .. " - AI " .. phaseManager.aiScore)
        end
        return
    end

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

    -- Use mirrored formations when appropriate
    local playerFormation = playerIsOffense and OFFENSIVE_FORMATION or DEFENSIVE_FORMATION_MIRRORED
    local aiFormation = playerIsOffense and DEFENSIVE_FORMATION or OFFENSIVE_FORMATION_MIRRORED

    -- Construct team labels with coach types
    local playerLabel = string.format("%s (%s)", playerTeamName, playerCoachName)
    local aiLabel = string.format("%s (%s)", aiTeamName, aiCoachName)

    -- Draw cards
    match.drawTeamCards(playerCards, "left", playerLabel, playerFormation)
    match.drawTeamCards(aiCards, "right", aiLabel, aiFormation)

    if paused then
        match.drawPauseMenu()
    end

    if matchEnded and winnerData then
        match.drawWinnerPopup()
    end
end

function match.drawUI()
    local screenWidth = UIScale.getWidth()
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)

    -- Phase indicator
    local phaseName = phaseManager:getCurrentPhaseName()
    love.graphics.printf("Phase: " .. phaseName, 0, UIScale.scaleY(15), screenWidth, "center")

    -- Yards display
    local totalYards = math.floor(phaseManager.field.totalYards)
    local yardsNeeded = phaseManager.field.yardsNeeded
    local downYards = math.floor(phaseManager.field.downYards)
    local yardsToFirst = math.floor(phaseManager.field:getYardsToFirstDown())

    love.graphics.printf(
        string.format("Yards: %d/%d | Down: %d  | %d yards to 1st",
        totalYards, yardsNeeded, phaseManager.field.currentDown, yardsToFirst),
        0, UIScale.scaleY(45), screenWidth, "center"
    )

    -- Down timer
    love.graphics.printf(
        string.format("Down Timer: %.1fs", phaseManager.field.downTimer),
        0, UIScale.scaleY(75), screenWidth, "center"
    )

    -- Team names and coaches
    love.graphics.printf(
        string.format("%s  vs  %s", playerTeamName, aiTeamName),
        0, UIScale.scaleY(105), screenWidth, "center"
    )
    love.graphics.setFont(smallFont)
    love.graphics.printf(
        string.format("(%s)  vs  (%s)", playerCoachName, aiCoachName),
        0, UIScale.scaleY(128), screenWidth, "center"
    )
    love.graphics.setFont(font)

    -- Score
    local playerScore = phaseManager.playerScore
    local aiScore = phaseManager.aiScore
    love.graphics.printf(
        string.format("Score: %d - %d", playerScore, aiScore),
        0, UIScale.scaleY(150), screenWidth, "center"
    )

    -- Game time with overtime indicator
    local timeDisplay = string.format("Time: %.1f", timeLeft)
    if inOvertime then
        local overtimeName = match.getOvertimeName(overtimePeriod)
        love.graphics.setColor(1, 0.8, 0)  -- Yellow/gold color for overtime
        love.graphics.printf(overtimeName, 0, UIScale.scaleY(180), screenWidth, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(timeDisplay, 0, UIScale.scaleY(210), screenWidth, "center")
    else
        love.graphics.printf(timeDisplay, 0, UIScale.scaleY(180), screenWidth, "center")
    end
end

function match.drawTeamCards(cards, side, teamName, formation)
    local startX = (side == "left") and UIScale.scaleX(150) or (UIScale.getWidth() - UIScale.scaleWidth(500))
    local startY = UIScale.scaleY(180)

    -- Draw team label
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(teamName, startX - UIScale.scaleWidth(50), startY - UIScale.scaleHeight(30), UIScale.scaleWidth(400), "center")

    -- Draw cards using formation (scale formation positions)
    for i, card in ipairs(cards) do
        if formation[i] then
            local pos = formation[i]
            local x = startX + UIScale.scaleX(pos.x)
            local y = startY + UIScale.scaleY(pos.y)
            match.drawCard(card, x, y)
        end
    end
end

function match.drawCard(card, x, y)
    local scaledCardWidth = UIScale.scaleWidth(CARD_WIDTH)
    local scaledCardHeight = UIScale.scaleHeight(CARD_HEIGHT)

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
    love.graphics.rectangle("fill", x, y, scaledCardWidth, scaledCardHeight, UIScale.scaleUniform(5), UIScale.scaleUniform(5))

    -- Draw card border
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(UIScale.scaleUniform(2))
    love.graphics.rectangle("line", x, y, scaledCardWidth, scaledCardHeight, UIScale.scaleUniform(5), UIScale.scaleUniform(5))

    -- Draw position name
    love.graphics.setFont(cardPositionFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(card.position, x, y + UIScale.scaleHeight(3), scaledCardWidth, "center")

    -- Draw stats based on card type
    local Card = require("card")
    if card.cardType == Card.TYPE.YARD_GENERATOR then
        love.graphics.setFont(cardStatsFont)
        love.graphics.printf(
            string.format("%.1f yd", card.yardsPerAction),
            x, y + UIScale.scaleHeight(16), scaledCardWidth, "center"
        )
    elseif card.cardType == Card.TYPE.BOOSTER then
        love.graphics.setFont(cardStatsFont)
        love.graphics.printf(
            string.format("+%d%%", card.boostAmount),
            x, y + UIScale.scaleHeight(16), scaledCardWidth, "center"
        )
    elseif card.cardType == Card.TYPE.DEFENDER then
        love.graphics.setFont(cardStatsFont)
        local effectName = card.effectType == Card.EFFECT.SLOW and "SLW" or
                          card.effectType == Card.EFFECT.FREEZE and "FRZ" or "REM"
        love.graphics.printf(effectName, x, y + UIScale.scaleHeight(16), scaledCardWidth, "center")
    end

    -- Draw jersey number (center of card)
    love.graphics.setFont(cardNumberFont)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.printf(
        string.format("#%d", card.number),
        x, y + UIScale.scaleHeight(32), scaledCardWidth, "center"
    )

    -- Draw upgrade count (top-right corner)
    if card.upgradeCount and card.upgradeCount > 0 then
        love.graphics.setFont(cardUpgradeFont)
        love.graphics.setColor(1, 0.8, 0.2)
        local upgradeText = string.format("+%d", card.upgradeCount)
        love.graphics.print(upgradeText, x + scaledCardWidth - UIScale.scaleWidth(20), y + UIScale.scaleHeight(3))
    end

    -- Draw progress bar
    local scaledProgressBarHeight = UIScale.scaleHeight(PROGRESS_BAR_HEIGHT)
    local progressBarY = y + scaledCardHeight - scaledProgressBarHeight - UIScale.scaleHeight(3)
    local progressBarWidth = scaledCardWidth - UIScale.scaleWidth(10)
    local progressBarX = x + UIScale.scaleWidth(5)

    -- Progress bar background
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", progressBarX, progressBarY, progressBarWidth, scaledProgressBarHeight)

    -- Progress bar fill
    local progress = card:getProgress()
    love.graphics.setColor(0.3, 0.7, 0.3)
    love.graphics.rectangle("fill", progressBarX, progressBarY, progressBarWidth * progress, scaledProgressBarHeight)

    -- Progress bar border
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineWidth(UIScale.scaleUniform(1))
    love.graphics.rectangle("line", progressBarX, progressBarY, progressBarWidth, scaledProgressBarHeight)
end

function match.drawPauseMenu()
    local screenWidth = UIScale.getWidth()
    local screenHeight = UIScale.getHeight()

    -- Apply slide animation
    love.graphics.push()
    love.graphics.translate(0, pauseMenuOffset.y)

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PAUSED", 0, UIScale.scaleY(300), screenWidth, "center")

    love.graphics.setFont(menuFont)
    local scaledButtonWidth = UIScale.scaleWidth(pauseButtonWidth)
    local scaledButtonHeight = UIScale.scaleHeight(pauseButtonHeight)

    for i, option in ipairs(pauseMenuOptions) do
        local x = UIScale.centerX(scaledButtonWidth)
        local y = UIScale.scaleY(pauseButtonY[i])

        if i == selectedPauseOption then
            love.graphics.setColor(0.3, 0.5, 0.7, 0.8)
        else
            love.graphics.setColor(0.2, 0.3, 0.4, 0.6)
        end
        love.graphics.rectangle("fill", x, y, scaledButtonWidth, scaledButtonHeight, 10, 10)

        if i == selectedPauseOption then
            love.graphics.setColor(0.5, 0.7, 1.0)
            love.graphics.setLineWidth(UIScale.scaleUniform(3))
        else
            love.graphics.setColor(0.4, 0.5, 0.6)
            love.graphics.setLineWidth(UIScale.scaleUniform(2))
        end
        love.graphics.rectangle("line", x, y, scaledButtonWidth, scaledButtonHeight, 10, 10)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(option, x, y + UIScale.scaleHeight(15), scaledButtonWidth, "center")
    end

    love.graphics.pop()
end

function match.drawWinnerPopup()
    local screenWidth = UIScale.getWidth()
    local screenHeight = UIScale.getHeight()

    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Popup background
    local scaledPopupWidth = UIScale.scaleWidth(700)
    local scaledPopupHeight = UIScale.scaleHeight(550)
    local popupX = UIScale.centerX(scaledPopupWidth)
    local popupY = UIScale.centerY(scaledPopupHeight)

    love.graphics.setColor(0.15, 0.2, 0.25)
    love.graphics.rectangle("fill", popupX, popupY, scaledPopupWidth, scaledPopupHeight, UIScale.scaleUniform(15), UIScale.scaleUniform(15))
    love.graphics.setColor(0.4, 0.5, 0.6)
    love.graphics.setLineWidth(UIScale.scaleUniform(3))
    love.graphics.rectangle("line", popupX, popupY, scaledPopupWidth, scaledPopupHeight, UIScale.scaleUniform(15), UIScale.scaleUniform(15))

    -- Winner title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.printf(winnerData.winnerName .. " WINS!", 0, popupY + UIScale.scaleHeight(30), screenWidth, "center")

    -- Coach name
    love.graphics.setFont(menuFont)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf(winnerData.winnerCoachName, 0, popupY + UIScale.scaleHeight(90), screenWidth, "center")

    -- Final score
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        string.format("Final Score:  Player %d - %d AI", winnerData.playerScore, winnerData.aiScore),
        0, popupY + UIScale.scaleHeight(135), screenWidth, "center"
    )

    -- MVP Section
    love.graphics.setFont(menuFont)
    love.graphics.setColor(0.9, 0.6, 0.3)
    love.graphics.printf("Players of the Game", 0, popupY + UIScale.scaleHeight(185), screenWidth, "center")

    -- Offensive MVP
    love.graphics.setFont(font)
    love.graphics.setColor(0.3, 0.8, 0.3)
    love.graphics.printf("Offensive Player:", popupX + UIScale.scaleWidth(50), popupY + UIScale.scaleHeight(235), scaledPopupWidth - UIScale.scaleWidth(100), "left")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        string.format("%s - %.1f yards, %d TDs",
            winnerData.offensiveMVP.position,
            tonumber(winnerData.offensiveMVP.yards),
            winnerData.offensiveMVP.touchdowns),
        popupX + UIScale.scaleWidth(50), popupY + UIScale.scaleHeight(265), scaledPopupWidth - UIScale.scaleWidth(100), "left"
    )

    -- Defensive MVP
    love.graphics.setColor(0.3, 0.6, 0.9)
    love.graphics.printf("Defensive Player:", popupX + UIScale.scaleWidth(50), popupY + UIScale.scaleHeight(315), scaledPopupWidth - UIScale.scaleWidth(100), "left")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        string.format("%s - %d slows, %d freezes, %.1f yards reduced",
            winnerData.defensiveMVP.position,
            winnerData.defensiveMVP.slows,
            winnerData.defensiveMVP.freezes,
            tonumber(winnerData.defensiveMVP.yardsReduced)),
        popupX + UIScale.scaleWidth(50), popupY + UIScale.scaleHeight(345), scaledPopupWidth - UIScale.scaleWidth(100), "left"
    )

    -- Return to Menu button
    local scaledButtonWidth = UIScale.scaleWidth(winnerButtonWidth)
    local scaledButtonHeight = UIScale.scaleHeight(winnerButtonHeight)
    local buttonX = UIScale.centerX(scaledButtonWidth)
    local buttonY = popupY + scaledPopupHeight - UIScale.scaleHeight(90)

    if winnerButtonHovered then
        love.graphics.setColor(0.3, 0.5, 0.7, 0.9)
    else
        love.graphics.setColor(0.2, 0.3, 0.4, 0.7)
    end
    love.graphics.rectangle("fill", buttonX, buttonY, scaledButtonWidth, scaledButtonHeight, UIScale.scaleUniform(10), UIScale.scaleUniform(10))

    if winnerButtonHovered then
        love.graphics.setColor(0.5, 0.7, 1.0)
        love.graphics.setLineWidth(UIScale.scaleUniform(3))
    else
        love.graphics.setColor(0.4, 0.5, 0.6)
        love.graphics.setLineWidth(UIScale.scaleUniform(2))
    end
    love.graphics.rectangle("line", buttonX, buttonY, scaledButtonWidth, scaledButtonHeight, UIScale.scaleUniform(10), UIScale.scaleUniform(10))

    love.graphics.setFont(menuFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Return to Menu", buttonX, buttonY + UIScale.scaleHeight(15), scaledButtonWidth, "center")
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

    -- Animate pause menu sliding down from top
    pauseMenuOffset.y = -UIScale.getHeight()
    flux.to(pauseMenuOffset, 0.3, {y = 0}):ease("quadout")
end

function match.resumeGame()
    paused = false
    selectedPauseOption = 0
end

function match.selectPauseOption(option)
    if option == 1 then
        match.resumeGame()
    elseif option == 2 then
        -- Options
        match.optionsRequested = true
    elseif option == 3 then
        love.event.quit()
    end
end

function match.mousepressed(x, y, button)
    if button == 1 then
        -- Winner popup button
        if matchEnded and winnerData then
            local scaledPopupHeight = UIScale.scaleHeight(550)
            local popupY = UIScale.centerY(scaledPopupHeight)
            local scaledButtonWidth = UIScale.scaleWidth(winnerButtonWidth)
            local scaledButtonHeight = UIScale.scaleHeight(winnerButtonHeight)
            local buttonX = UIScale.centerX(scaledButtonWidth)
            local buttonY = popupY + scaledPopupHeight - UIScale.scaleHeight(90)

            if x >= buttonX and x <= buttonX + scaledButtonWidth and
               y >= buttonY and y <= buttonY + scaledButtonHeight then
                match.returnToMenu()
                return
            end
        end

        -- Pause menu buttons
        if paused then
            local scaledButtonWidth = UIScale.scaleWidth(pauseButtonWidth)
            local scaledButtonHeight = UIScale.scaleHeight(pauseButtonHeight)
            local buttonX = UIScale.centerX(scaledButtonWidth)

            for i = 1, #pauseMenuOptions do
                local buttonYPos = UIScale.scaleY(pauseButtonY[i])
                if x >= buttonX and x <= buttonX + scaledButtonWidth and
                   y >= buttonYPos and y <= buttonYPos + scaledButtonHeight then
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
        local scaledPopupHeight = UIScale.scaleHeight(550)
        local popupY = UIScale.centerY(scaledPopupHeight)
        local scaledButtonWidth = UIScale.scaleWidth(winnerButtonWidth)
        local scaledButtonHeight = UIScale.scaleHeight(winnerButtonHeight)
        local buttonX = UIScale.centerX(scaledButtonWidth)
        local buttonY = popupY + scaledPopupHeight - UIScale.scaleHeight(90)

        winnerButtonHovered = (x >= buttonX and x <= buttonX + scaledButtonWidth and
                               y >= buttonY and y <= buttonY + scaledButtonHeight)
        return
    end

    -- Pause menu button hover
    if paused then
        local scaledButtonWidth = UIScale.scaleWidth(pauseButtonWidth)
        local scaledButtonHeight = UIScale.scaleHeight(pauseButtonHeight)
        local buttonX = UIScale.centerX(scaledButtonWidth)
        selectedPauseOption = 0

        for i = 1, #pauseMenuOptions do
            local buttonYPos = UIScale.scaleY(pauseButtonY[i])
            if x >= buttonX and x <= buttonX + scaledButtonWidth and
               y >= buttonYPos and y <= buttonYPos + scaledButtonHeight then
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

--- Gets the current player score
--- @return number Player score
function match.getPlayerScore()
    return phaseManager and phaseManager.playerScore or 0
end

--- Gets the current AI score
--- @return number AI score
function match.getAIScore()
    return phaseManager and phaseManager.aiScore or 0
end

--- Gets the offensive MVP card
--- @return table|nil MVP card or nil
function match.getMVPOffense()
    return winnerData and winnerData.offensiveMVP or nil
end

--- Gets the defensive MVP card
--- @return table|nil MVP card or nil
function match.getMVPDefense()
    return winnerData and winnerData.defensiveMVP or nil
end

--- Gets the player's offensive cards from the current match
--- @return table Array of offensive cards
function match.getPlayerOffensiveCards()
    return phaseManager and phaseManager.playerOffense.cards or {}
end

--- Gets the player's defensive cards from the current match
--- @return table Array of defensive cards
function match.getPlayerDefensiveCards()
    return phaseManager and phaseManager.playerDefense.cards or {}
end

--- Simulates a match between two AI teams without rendering
--- Runs at accelerated speed for quick results
--- @param teamA table Home team
--- @param teamB table Away team
--- @return number, number Home score, away score
function match.simulateAIMatch(teamA, teamB)
    -- Create a temporary phase manager for simulation
    local simPhaseManager = PhaseManager:new(teamA.coachId, teamB.coachId)

    local simTime = matchTime
    local simInOvertime = false
    local simOvertimePeriod = 0
    local timeStep = 0.1  -- Simulate in 0.1 second increments

    -- Run regulation time
    while simTime > 0 do
        simPhaseManager:update(timeStep)
        simPhaseManager:checkPhaseEnd()  -- Critical: Check for phase transitions and scoring
        simTime = simTime - timeStep
    end

    -- Handle overtime if tied
    while simPhaseManager.playerScore == simPhaseManager.aiScore do
        simInOvertime = true
        simOvertimePeriod = simOvertimePeriod + 1
        simTime = overtimeTime

        while simTime > 0 do
            simPhaseManager:update(timeStep)
            simPhaseManager:checkPhaseEnd()  -- Critical: Check for phase transitions and scoring
            simTime = simTime - timeStep
        end

        -- Prevent infinite overtime (safety)
        if simOvertimePeriod > 10 then
            -- Force a winner by adding 1 point to random team
            if math.random() > 0.5 then
                simPhaseManager.playerScore = simPhaseManager.playerScore + 1
            else
                simPhaseManager.aiScore = simPhaseManager.aiScore + 1
            end
            break
        end
    end

    return simPhaseManager.playerScore, simPhaseManager.aiScore
end

return match
