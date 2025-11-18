--- scouting_screen.lua
--- Scouting Screen (Next Match)
---
--- Displays full scouting report for the next opponent.
--- Shows opponent's offensive and defensive cards with exact stats.
--- Includes "Start Match" button to begin the game.
---
--- Dependencies: season_manager.lua, card.lua
--- Used by: season_menu.lua
--- LÖVE Callbacks: love.update, love.draw, love.mousepressed

local ScoutingScreen = {}

local SeasonManager = require("season_manager")
local Card = require("card")
local UIScale = require("ui_scale")

-- State
ScoutingScreen.opponent = nil
ScoutingScreen.matchData = nil
ScoutingScreen.hoveredCard = nil
ScoutingScreen.startMatchRequested = false
ScoutingScreen.simulateMatchRequested = false
ScoutingScreen.playoffsSimulated = false
ScoutingScreen.viewBracketRequested = false
ScoutingScreen.contentHeight = 700

-- UI configuration (base values for 1600x900)
local CARD_WIDTH = 120
local CARD_HEIGHT = 80
local CARD_SPACING = 15
local SECTION_Y_OFFSET = 50
local START_BUTTON_WIDTH = 250
local START_BUTTON_HEIGHT = 60

-- Fonts
local titleFont
local matchupFont
local recordFont
local sectionFont
local cardPositionFont
local cardNumberFont
local buttonFont
local tooltipHeaderFont
local tooltipTextFont

--- Initializes the scouting screen
function ScoutingScreen.load()
    -- Update UI scale
    UIScale.update()

    -- Create fonts
    titleFont = love.graphics.newFont(UIScale.scaleFontSize(32))
    matchupFont = love.graphics.newFont(UIScale.scaleFontSize(24))
    recordFont = love.graphics.newFont(UIScale.scaleFontSize(20))
    sectionFont = love.graphics.newFont(UIScale.scaleFontSize(26))
    cardPositionFont = love.graphics.newFont(UIScale.scaleFontSize(20))
    cardNumberFont = love.graphics.newFont(UIScale.scaleFontSize(28))
    buttonFont = love.graphics.newFont(UIScale.scaleFontSize(28))
    tooltipHeaderFont = love.graphics.newFont(UIScale.scaleFontSize(22))
    tooltipTextFont = love.graphics.newFont(UIScale.scaleFontSize(18))

    ScoutingScreen.hoveredCard = nil
    ScoutingScreen.startMatchRequested = false
    ScoutingScreen.simulateMatchRequested = false
    ScoutingScreen.viewBracketRequested = false

    -- Check if playoffs were already simulated
    if SeasonManager.playoffBracket and SeasonManager.playoffBracket.fullySimulated then
        ScoutingScreen.playoffsSimulated = true
    else
        ScoutingScreen.playoffsSimulated = false
    end

    -- Get next opponent
    ScoutingScreen.matchData = SeasonManager.getPlayerMatch()

    if ScoutingScreen.matchData then
        ScoutingScreen.opponent = ScoutingScreen.matchData.opponentTeam
    else
        ScoutingScreen.opponent = nil
    end
end

--- LÖVE Callback: Update Logic
--- @param dt number Delta time in seconds
function ScoutingScreen.update(dt)
    -- Update hovered card
    local mx, my = love.mouse.getPosition()
    my = my - UIScale.scaleHeight(100)  -- Adjust for header

    ScoutingScreen.hoveredCard = ScoutingScreen.getCardAtPosition(mx, my)
end

--- LÖVE Callback: Draw UI
function ScoutingScreen.draw()
    -- Check for bye week
    local hasByeWeek = SeasonManager.playerHasByeWeek()

    -- Check if player is eliminated
    if ScoutingScreen.playerIsEliminated() and not hasByeWeek then
        ScoutingScreen.drawEliminatedScreen()
        return
    end

    if not ScoutingScreen.opponent and not hasByeWeek then
        -- No upcoming match and no bye week
        love.graphics.setFont(buttonFont)
        love.graphics.setColor(0.8, 0.8, 0.9)
        local noMatchText = "No upcoming match. Season may be complete."
        local textWidth = buttonFont:getWidth(noMatchText)
        love.graphics.print(noMatchText, UIScale.centerX(textWidth), UIScale.scaleY(300))
        return
    end

    -- Handle bye week display
    if hasByeWeek then
        ScoutingScreen.drawByeWeek()
        return
    end

    local yOffset = UIScale.scaleY(20)
    local startX = UIScale.scaleX(50)

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Next Match Scouting Report", startX, yOffset)

    yOffset = yOffset + UIScale.scaleHeight(50)

    -- Matchup info
    love.graphics.setFont(matchupFont)
    love.graphics.setColor(0.8, 0.9, 1)

    local matchupText = ""
    if ScoutingScreen.matchData.isHome then
        matchupText = string.format("%s vs %s (Home)", SeasonManager.playerTeam.name, ScoutingScreen.opponent.name)
    else
        matchupText = string.format("%s @ %s (Away)", SeasonManager.playerTeam.name, ScoutingScreen.opponent.name)
    end
    love.graphics.print(matchupText, startX, yOffset)

    yOffset = yOffset + UIScale.scaleHeight(40)

    -- Opponent record
    love.graphics.setFont(recordFont)
    love.graphics.setColor(0.7, 0.7, 0.8)
    local recordText = string.format("Opponent Record: %s", ScoutingScreen.opponent:getRecordString())
    love.graphics.print(recordText, startX, yOffset)

    yOffset = yOffset + UIScale.scaleHeight(30)

    -- Coach difficulty rating with stars
    local Coach = require("coach")
    local coachData = Coach.getById(ScoutingScreen.opponent.coachId)
    if coachData and coachData.difficulty then
        local stars = Coach.getStarRating(coachData.difficulty)
        local difficultyName = Coach.getDifficultyName(coachData.difficulty)

        love.graphics.setColor(0.9, 0.8, 0.5)
        love.graphics.print(string.format("Coach: %s ", coachData.name), startX, yOffset)

        -- Draw stars
        local starX = startX + recordFont:getWidth(string.format("Coach: %s ", coachData.name))
        for i = 1, 5 do
            if i <= stars then
                love.graphics.setColor(1, 0.84, 0)  -- Gold for filled stars
                love.graphics.print("★", starX, yOffset)
            else
                love.graphics.setColor(0.3, 0.3, 0.3)  -- Dark gray for empty stars
                love.graphics.print("☆", starX, yOffset)
            end
            starX = starX + recordFont:getWidth("★ ")
        end

        -- Difficulty label
        love.graphics.setColor(0.6, 0.6, 0.7)
        love.graphics.print(string.format(" (%s)", difficultyName), starX, yOffset)
    end

    yOffset = yOffset + UIScale.scaleHeight(50)

    -- Offensive cards
    love.graphics.setFont(sectionFont)
    love.graphics.setColor(0.3, 0.8, 0.3)
    love.graphics.print("Opponent Offense", startX, yOffset)

    yOffset = yOffset + UIScale.scaleHeight(SECTION_Y_OFFSET)
    ScoutingScreen.drawCardRow(ScoutingScreen.opponent.offensiveCards, yOffset)

    yOffset = yOffset + UIScale.scaleHeight(CARD_HEIGHT + 60)

    -- Defensive cards
    love.graphics.setFont(sectionFont)
    love.graphics.setColor(0.8, 0.3, 0.3)
    love.graphics.print("Opponent Defense", startX, yOffset)

    yOffset = yOffset + UIScale.scaleHeight(SECTION_Y_OFFSET)
    ScoutingScreen.drawCardRow(ScoutingScreen.opponent.defensiveCards, yOffset)

    yOffset = yOffset + UIScale.scaleHeight(CARD_HEIGHT + 60)

    -- Special Teams
    love.graphics.setFont(sectionFont)
    love.graphics.setColor(0.4, 0.9, 0.4)
    love.graphics.print("Opponent Special Teams", startX, yOffset)

    yOffset = yOffset + UIScale.scaleHeight(SECTION_Y_OFFSET)
    local specialTeamsCards = {}
    if ScoutingScreen.opponent.kicker then
        table.insert(specialTeamsCards, ScoutingScreen.opponent.kicker)
    end
    if ScoutingScreen.opponent.punter then
        table.insert(specialTeamsCards, ScoutingScreen.opponent.punter)
    end
    ScoutingScreen.drawCardRow(specialTeamsCards, yOffset)

    -- Action buttons (Start Match and Simulate Game)
    local scaledButtonWidth = UIScale.scaleWidth(START_BUTTON_WIDTH)
    local scaledButtonHeight = UIScale.scaleHeight(START_BUTTON_HEIGHT)
    local buttonSpacing = UIScale.scaleUniform(20)
    local totalWidth = (scaledButtonWidth * 2) + buttonSpacing
    local startX = UIScale.centerX(totalWidth)
    local buttonY = UIScale.scaleHeight(ScoutingScreen.contentHeight - START_BUTTON_HEIGHT - 30)

    local mx, my = love.mouse.getPosition()
    my = my - UIScale.scaleHeight(100)  -- Adjust for header

    -- Start Match button (left)
    local startButtonX = startX
    local hoveringStartButton = mx >= startButtonX and mx <= startButtonX + scaledButtonWidth and
                                my >= buttonY and my <= buttonY + scaledButtonHeight

    if hoveringStartButton then
        love.graphics.setColor(0.3, 0.6, 0.3)
    else
        love.graphics.setColor(0.2, 0.5, 0.2)
    end
    love.graphics.rectangle("fill", startButtonX, buttonY, scaledButtonWidth, scaledButtonHeight)

    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(UIScale.scaleUniform(3))
    love.graphics.rectangle("line", startButtonX, buttonY, scaledButtonWidth, scaledButtonHeight)

    love.graphics.setFont(buttonFont)
    love.graphics.setColor(1, 1, 1)
    local startButtonText = "Start Match"
    local startButtonTextWidth = buttonFont:getWidth(startButtonText)
    love.graphics.print(startButtonText, startButtonX + (scaledButtonWidth - startButtonTextWidth) / 2, buttonY + UIScale.scaleHeight(15))

    -- Simulate Game button (right)
    local simulateButtonX = startX + scaledButtonWidth + buttonSpacing
    local hoveringSimulateButton = mx >= simulateButtonX and mx <= simulateButtonX + scaledButtonWidth and
                                   my >= buttonY and my <= buttonY + scaledButtonHeight

    if hoveringSimulateButton then
        love.graphics.setColor(0.4, 0.5, 0.7)
    else
        love.graphics.setColor(0.3, 0.4, 0.6)
    end
    love.graphics.rectangle("fill", simulateButtonX, buttonY, scaledButtonWidth, scaledButtonHeight)

    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(UIScale.scaleUniform(3))
    love.graphics.rectangle("line", simulateButtonX, buttonY, scaledButtonWidth, scaledButtonHeight)

    love.graphics.setFont(buttonFont)
    love.graphics.setColor(1, 1, 1)
    local simulateButtonText = "Simulate Game"
    local simulateButtonTextWidth = buttonFont:getWidth(simulateButtonText)
    love.graphics.print(simulateButtonText, simulateButtonX + (scaledButtonWidth - simulateButtonTextWidth) / 2, buttonY + UIScale.scaleHeight(15))

    -- Draw tooltip if hovering
    if ScoutingScreen.hoveredCard then
        ScoutingScreen.drawTooltip(ScoutingScreen.hoveredCard)
    end
end

--- Draws a row of cards
--- @param cards table Array of cards
--- @param y number Y position
function ScoutingScreen.drawCardRow(cards, y)
    local mx, my = love.mouse.getPosition()
    my = my - UIScale.scaleHeight(100)  -- Adjust for header

    local scaledCardWidth = UIScale.scaleWidth(CARD_WIDTH)
    local scaledCardSpacing = UIScale.scaleUniform(CARD_SPACING)
    local startX = UIScale.scaleX(50)

    for i, card in ipairs(cards) do
        local x = startX + ((i - 1) * (scaledCardWidth + scaledCardSpacing))
        ScoutingScreen.drawCard(card, x, y, mx, my)
    end
end

--- Draws a single card
--- @param card table The card data
--- @param x number X position
--- @param y number Y position
--- @param mx number Mouse X position
--- @param my number Mouse Y position
function ScoutingScreen.drawCard(card, x, y, mx, my)
    local scaledCardWidth = UIScale.scaleWidth(CARD_WIDTH)
    local scaledCardHeight = UIScale.scaleHeight(CARD_HEIGHT)

    local hovering = mx >= x and mx <= x + scaledCardWidth and
                    my >= y and my <= y + scaledCardHeight

    -- Background
    if hovering then
        love.graphics.setColor(0.3, 0.35, 0.4)
    else
        love.graphics.setColor(0.2, 0.2, 0.25)
    end
    love.graphics.rectangle("fill", x, y, scaledCardWidth, scaledCardHeight)

    -- Border
    if card.cardType == Card.TYPE.YARD_GENERATOR then
        love.graphics.setColor(0.3, 0.7, 0.3)
    elseif card.cardType == Card.TYPE.BOOSTER then
        love.graphics.setColor(0.3, 0.5, 0.8)
    elseif card.cardType == Card.TYPE.DEFENDER then
        love.graphics.setColor(0.8, 0.3, 0.3)
    end
    love.graphics.setLineWidth(UIScale.scaleUniform(2))
    love.graphics.rectangle("line", x, y, scaledCardWidth, scaledCardHeight)

    -- Position and number
    love.graphics.setFont(cardPositionFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(card.position, x + UIScale.scaleUniform(10), y + UIScale.scaleHeight(10))

    love.graphics.setFont(cardNumberFont)
    local numText = string.format("#%d", card.number)
    love.graphics.print(numText, x + UIScale.scaleUniform(10), y + UIScale.scaleHeight(35))

    -- Upgrade indicator (if card has been upgraded)
    if card.upgradeCount and card.upgradeCount > 0 then
        local badgeSize = UIScale.scaleUniform(18)
        local badgeX = x + scaledCardWidth - badgeSize - UIScale.scaleUniform(5)
        local badgeY = y + UIScale.scaleHeight(5)

        -- Badge color based on upgrade count
        if card.upgradeCount == 1 then
            -- Bronze
            love.graphics.setColor(0.8, 0.5, 0.2, 0.95)
        elseif card.upgradeCount == 2 then
            -- Silver
            love.graphics.setColor(0.75, 0.75, 0.75, 0.95)
        else
            -- Gold (3+)
            love.graphics.setColor(1, 0.84, 0, 0.95)
        end
        love.graphics.circle("fill", badgeX + badgeSize/2, badgeY + badgeSize/2, badgeSize/2)

        -- Badge border
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.setLineWidth(UIScale.scaleUniform(2))
        love.graphics.circle("line", badgeX + badgeSize/2, badgeY + badgeSize/2, badgeSize/2)
    end
end

--- Gets the card at the given mouse position
--- @param mx number Mouse X position
--- @param my number Mouse Y position
--- @return table|nil The card at the position, or nil
function ScoutingScreen.getCardAtPosition(mx, my)
    if not ScoutingScreen.opponent then
        return nil
    end

    local scaledCardWidth = UIScale.scaleWidth(CARD_WIDTH)
    local scaledCardHeight = UIScale.scaleHeight(CARD_HEIGHT)
    local scaledCardSpacing = UIScale.scaleUniform(CARD_SPACING)
    local startX = UIScale.scaleX(50)
    local yOffset = UIScale.scaleY(20 + 50 + 40 + 50) + UIScale.scaleHeight(SECTION_Y_OFFSET)

    -- Check offensive cards
    for i, card in ipairs(ScoutingScreen.opponent.offensiveCards) do
        local x = startX + ((i - 1) * (scaledCardWidth + scaledCardSpacing))
        if mx >= x and mx <= x + scaledCardWidth and my >= yOffset and my <= yOffset + scaledCardHeight then
            return card
        end
    end

    yOffset = yOffset + UIScale.scaleHeight(CARD_HEIGHT + 60 + SECTION_Y_OFFSET)

    -- Check defensive cards
    for i, card in ipairs(ScoutingScreen.opponent.defensiveCards) do
        local x = startX + ((i - 1) * (scaledCardWidth + scaledCardSpacing))
        if mx >= x and mx <= x + scaledCardWidth and my >= yOffset and my <= yOffset + scaledCardHeight then
            return card
        end
    end

    yOffset = yOffset + UIScale.scaleHeight(CARD_HEIGHT + 60 + SECTION_Y_OFFSET)

    -- Check special teams cards
    local specialTeamsCards = {}
    if ScoutingScreen.opponent.kicker then
        table.insert(specialTeamsCards, ScoutingScreen.opponent.kicker)
    end
    if ScoutingScreen.opponent.punter then
        table.insert(specialTeamsCards, ScoutingScreen.opponent.punter)
    end
    for i, card in ipairs(specialTeamsCards) do
        local x = startX + ((i - 1) * (scaledCardWidth + scaledCardSpacing))
        if mx >= x and mx <= x + scaledCardWidth and my >= yOffset and my <= yOffset + scaledCardHeight then
            return card
        end
    end

    return nil
end

--- Draws a tooltip for a card
--- @param card table The card to show tooltip for
function ScoutingScreen.drawTooltip(card)
    local mx, my = love.mouse.getPosition()

    local tooltipWidth = UIScale.scaleWidth(300)
    local tooltipHeight = 0
    local padding = UIScale.scaleUniform(15)
    local lineHeight = UIScale.scaleHeight(25)

    -- Calculate tooltip height
    local lines = 5
    if card.cardType == Card.TYPE.YARD_GENERATOR then
        lines = lines + 2
    elseif card.cardType == Card.TYPE.BOOSTER then
        lines = lines + 2
    elseif card.cardType == Card.TYPE.DEFENDER then
        lines = lines + 3
    elseif card.cardType == Card.TYPE.KICKER then
        lines = lines + 2
    elseif card.cardType == Card.TYPE.PUNTER then
        lines = lines + 2
    end

    -- Add line for upgrade count if upgraded
    if card.upgradeCount and card.upgradeCount > 0 then
        lines = lines + 1
    end

    tooltipHeight = (lines * lineHeight) + (padding * 2)

    -- Position tooltip
    local tooltipX = mx + UIScale.scaleUniform(15)
    local tooltipY = my - tooltipHeight / 2

    if tooltipX + tooltipWidth > UIScale.getWidth() then
        tooltipX = mx - tooltipWidth - UIScale.scaleUniform(15)
    end

    if tooltipY < 0 then
        tooltipY = 0
    end
    if tooltipY + tooltipHeight > UIScale.getHeight() then
        tooltipY = UIScale.getHeight() - tooltipHeight
    end

    -- Background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
    love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipWidth, tooltipHeight)

    -- Border
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.setLineWidth(UIScale.scaleUniform(2))
    love.graphics.rectangle("line", tooltipX, tooltipY, tooltipWidth, tooltipHeight)

    -- Content
    local contentY = tooltipY + padding
    love.graphics.setFont(tooltipHeaderFont)

    -- Position and number
    love.graphics.setColor(1, 1, 1)
    local headerText = string.format("%s #%d", card.position, card.number)
    love.graphics.print(headerText, tooltipX + padding, contentY)
    contentY = contentY + lineHeight

    -- Type
    love.graphics.setFont(tooltipTextFont)
    love.graphics.setColor(0.8, 0.8, 0.9)
    local typeText = ""
    if card.cardType == Card.TYPE.YARD_GENERATOR then
        typeText = "Yard Generator"
    elseif card.cardType == Card.TYPE.BOOSTER then
        typeText = "Booster"
    elseif card.cardType == Card.TYPE.DEFENDER then
        typeText = "Defender"
    elseif card.cardType == Card.TYPE.KICKER then
        typeText = "Kicker"
    elseif card.cardType == Card.TYPE.PUNTER then
        typeText = "Punter"
    end
    love.graphics.print(typeText, tooltipX + padding, contentY)
    contentY = contentY + lineHeight

    -- Upgrade tier (if upgraded)
    if card.upgradeCount and card.upgradeCount > 0 then
        local tierName, tierColor
        if card.upgradeCount == 1 then
            tierName = "Bronze"
            tierColor = {0.8, 0.5, 0.2}
        elseif card.upgradeCount == 2 then
            tierName = "Silver"
            tierColor = {0.75, 0.75, 0.75}
        else
            tierName = "Gold"
            tierColor = {1, 0.84, 0}
        end
        love.graphics.setColor(tierColor)
        love.graphics.print(string.format("Tier: %s (%d)", tierName, card.upgradeCount), tooltipX + padding, contentY)
        contentY = contentY + lineHeight
    end

    contentY = contentY + UIScale.scaleHeight(5)

    -- Stats
    love.graphics.setColor(0.9, 0.9, 1)

    if card.cardType == Card.TYPE.YARD_GENERATOR then
        love.graphics.print(string.format("Yards: %.1f-%.1f", card.yardsPerActionMin, card.yardsPerActionMax), tooltipX + padding, contentY)
        contentY = contentY + lineHeight
        love.graphics.print(string.format("Cooldown: %.2fs", card.cooldown), tooltipX + padding, contentY)
        contentY = contentY + lineHeight

    elseif card.cardType == Card.TYPE.BOOSTER then
        love.graphics.print(string.format("Boost: +%d-%d%%", math.floor(card.boostAmountMin), math.ceil(card.boostAmountMax)), tooltipX + padding, contentY)
        contentY = contentY + lineHeight
        love.graphics.print(string.format("Cooldown: %.2fs", card.cooldown), tooltipX + padding, contentY)
        contentY = contentY + lineHeight

    elseif card.cardType == Card.TYPE.DEFENDER then
        love.graphics.print(string.format("Effect: %s (%.1f-%.1f)", card.effectType, card.effectStrengthMin, card.effectStrengthMax), tooltipX + padding, contentY)
        contentY = contentY + lineHeight
        love.graphics.print(string.format("Cooldown: %.2fs", card.cooldown), tooltipX + padding, contentY)
        contentY = contentY + lineHeight

    elseif card.cardType == Card.TYPE.KICKER then
        love.graphics.print(string.format("Max Range: %d yards", card.kickerMaxRange), tooltipX + padding, contentY)
        contentY = contentY + lineHeight
        love.graphics.print(string.format("Max Range Accuracy: %d%%", card.kickerMaxRangeAccuracy), tooltipX + padding, contentY)
        contentY = contentY + lineHeight

    elseif card.cardType == Card.TYPE.PUNTER then
        love.graphics.print(string.format("Range: %d-%d yards", card.punterMinRange, card.punterMaxRange), tooltipX + padding, contentY)
        contentY = contentY + lineHeight
    end
end

--- Draws the bye week screen with "Simulate Week" button
function ScoutingScreen.drawByeWeek()
    local yOffset = UIScale.scaleY(150)
    local startX = UIScale.scaleX(50)

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 0.9, 0.3)
    local titleText = "WILDCARD ROUND - BYE WEEK"
    local titleWidth = titleFont:getWidth(titleText)
    love.graphics.print(titleText, UIScale.centerX(titleWidth), yOffset)

    yOffset = yOffset + UIScale.scaleHeight(80)

    -- Message
    love.graphics.setFont(matchupFont)
    love.graphics.setColor(0.9, 0.9, 1)
    local msg1 = "Congratulations! Your team has earned a first-round bye."
    local msg1Width = matchupFont:getWidth(msg1)
    love.graphics.print(msg1, UIScale.centerX(msg1Width), yOffset)

    yOffset = yOffset + UIScale.scaleHeight(40)

    local msg2 = "You will automatically advance to the Divisional Round."
    local msg2Width = matchupFont:getWidth(msg2)
    love.graphics.print(msg2, UIScale.centerX(msg2Width), yOffset)

    yOffset = yOffset + UIScale.scaleHeight(60)

    local msg3 = "Click below to simulate the 4 Wildcard Round games."
    local msg3Width = matchupFont:getWidth(msg3)
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.print(msg3, UIScale.centerX(msg3Width), yOffset)

    -- Simulate Week button
    local scaledButtonWidth = UIScale.scaleWidth(START_BUTTON_WIDTH)
    local scaledButtonHeight = UIScale.scaleHeight(START_BUTTON_HEIGHT)
    local buttonX = UIScale.centerX(scaledButtonWidth)
    local buttonY = UIScale.scaleHeight(ScoutingScreen.contentHeight - START_BUTTON_HEIGHT - 30)

    local mx, my = love.mouse.getPosition()
    my = my - UIScale.scaleHeight(100)  -- Adjust for header
    local hoveringButton = mx >= buttonX and mx <= buttonX + scaledButtonWidth and
                          my >= buttonY and my <= buttonY + scaledButtonHeight

    -- Button
    if hoveringButton then
        love.graphics.setColor(0.4, 0.6, 0.8)
    else
        love.graphics.setColor(0.3, 0.5, 0.7)
    end
    love.graphics.rectangle("fill", buttonX, buttonY, scaledButtonWidth, scaledButtonHeight)

    love.graphics.setColor(0.6, 0.8, 1)
    love.graphics.setLineWidth(UIScale.scaleUniform(3))
    love.graphics.rectangle("line", buttonX, buttonY, scaledButtonWidth, scaledButtonHeight)

    love.graphics.setFont(buttonFont)
    love.graphics.setColor(1, 1, 1)
    local buttonText = "Simulate Week"
    local buttonTextWidth = buttonFont:getWidth(buttonText)
    love.graphics.print(buttonText, buttonX + (scaledButtonWidth - buttonTextWidth) / 2, buttonY + UIScale.scaleHeight(15))
end

--- LÖVE Callback: Mouse Pressed
--- @param x number Mouse X position
--- @param y number Mouse Y position
--- @param button number Mouse button
function ScoutingScreen.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    -- Check if on eliminated screen
    if ScoutingScreen.playerIsEliminated() and not SeasonManager.playerHasByeWeek() then
        -- Button click detection for eliminated screen
        -- Note: We can't easily calculate the exact y position without duplicating logic,
        -- so we'll use a more generous hit detection area
        local scaledButtonWidth = UIScale.scaleWidth(START_BUTTON_WIDTH)
        local scaledButtonHeight = UIScale.scaleHeight(START_BUTTON_HEIGHT)
        local buttonX = UIScale.centerX(scaledButtonWidth)

        -- Check if click is in general button area (anywhere in lower half of screen)
        if x >= buttonX and x <= buttonX + scaledButtonWidth and
           y >= UIScale.scaleHeight(400) and y <= UIScale.scaleHeight(650) then
            if ScoutingScreen.playoffsSimulated then
                -- Navigate to bracket view
                ScoutingScreen.viewBracketRequested = true
            else
                -- Will be handled in main.lua to simulate playoffs
                ScoutingScreen.simulateMatchRequested = true
            end
        end
        return
    end

    local scaledButtonWidth = UIScale.scaleWidth(START_BUTTON_WIDTH)
    local scaledButtonHeight = UIScale.scaleHeight(START_BUTTON_HEIGHT)
    local buttonSpacing = UIScale.scaleUniform(20)
    local totalWidth = (scaledButtonWidth * 2) + buttonSpacing
    local startX = UIScale.centerX(totalWidth)
    local buttonY = UIScale.scaleHeight(ScoutingScreen.contentHeight - START_BUTTON_HEIGHT - 30)

    -- Check if bye week - only show simulate button
    if SeasonManager.playerHasByeWeek() then
        local buttonX = UIScale.centerX(scaledButtonWidth)
        if x >= buttonX and x <= buttonX + scaledButtonWidth and
           y >= buttonY and y <= buttonY + scaledButtonHeight then
            SeasonManager.simulateWildcardRound()
            -- Reload to show divisional matchup
            ScoutingScreen.load()
        end
        return
    end

    -- Start Match button (left)
    local startButtonX = startX
    if x >= startButtonX and x <= startButtonX + scaledButtonWidth and
       y >= buttonY and y <= buttonY + scaledButtonHeight then
        ScoutingScreen.startMatchRequested = true
        return
    end

    -- Simulate Game button (right)
    local simulateButtonX = startX + scaledButtonWidth + buttonSpacing
    if x >= simulateButtonX and x <= simulateButtonX + scaledButtonWidth and
       y >= buttonY and y <= buttonY + scaledButtonHeight then
        ScoutingScreen.simulateMatchRequested = true
        return
    end
end

--- Checks if start match was requested
--- @return boolean True if button clicked
function ScoutingScreen.isStartMatchRequested()
    return ScoutingScreen.startMatchRequested
end

--- Checks if simulate match was requested
--- @return boolean True if button clicked
function ScoutingScreen.isSimulateMatchRequested()
    return ScoutingScreen.simulateMatchRequested
end

--- Checks if view bracket was requested
--- @return boolean True if button clicked
function ScoutingScreen.isViewBracketRequested()
    return ScoutingScreen.viewBracketRequested
end

--- Checks if player is eliminated (wrapper for SeasonManager function)
--- @return boolean True if player is eliminated
function ScoutingScreen.playerIsEliminated()
    return SeasonManager.playerIsEliminated()
end

--- Draws the eliminated screen with season summary and playoff simulation button
function ScoutingScreen.drawEliminatedScreen()
    local yOffset = UIScale.scaleY(80)
    local Coach = require("coach")

    -- Player's Team Name
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    local teamName = SeasonManager.playerTeam.name
    local teamNameWidth = titleFont:getWidth(teamName)
    love.graphics.print(teamName, UIScale.centerX(teamNameWidth), yOffset)

    yOffset = yOffset + UIScale.scaleHeight(50)

    -- Player's Coaching Style
    love.graphics.setFont(matchupFont)
    love.graphics.setColor(0.9, 0.8, 0.5)
    local coachData = Coach.getById(SeasonManager.playerTeam.coachId)
    local coachName = coachData and coachData.name or "Unknown"
    local coachNameWidth = matchupFont:getWidth(coachName)
    love.graphics.print(coachName, UIScale.centerX(coachNameWidth), yOffset)

    yOffset = yOffset + UIScale.scaleHeight(40)

    -- Player's Final Record
    love.graphics.setFont(recordFont)
    love.graphics.setColor(0.8, 0.9, 1)
    local recordText = "Final Record: " .. SeasonManager.playerTeam:getRecordString()
    local recordWidth = recordFont:getWidth(recordText)
    love.graphics.print(recordText, UIScale.centerX(recordWidth), yOffset)

    yOffset = yOffset + UIScale.scaleHeight(35)

    -- Final Conference Standing
    local standing = SeasonManager.getPlayerFinalStanding()
    if standing then
        local standingText = string.format("%d%s in Conference %s",
            standing,
            standing == 1 and "st" or (standing == 2 and "nd" or (standing == 3 and "rd" or "th")),
            SeasonManager.playerTeam.conference)
        local standingWidth = recordFont:getWidth(standingText)
        love.graphics.print(standingText, UIScale.centerX(standingWidth), yOffset)

        yOffset = yOffset + UIScale.scaleHeight(35)
    end

    -- Elimination Message
    love.graphics.setFont(matchupFont)
    love.graphics.setColor(1, 0.7, 0.7)
    local eliminationMsg
    if not SeasonManager.inPlayoffs then
        eliminationMsg = "Did not qualify for playoffs"
    else
        -- Determine which round they were eliminated in
        local currentRound = SeasonManager.playoffBracket and SeasonManager.playoffBracket.currentRound
        if currentRound == "divisional" then
            eliminationMsg = "Eliminated in Wild Card Round"
        elseif currentRound == "conference" then
            eliminationMsg = "Eliminated in Divisional Round"
        elseif currentRound == "championship" then
            eliminationMsg = "Eliminated in Conference Championship"
        else
            eliminationMsg = "Eliminated from playoffs"
        end
    end
    local eliminationWidth = matchupFont:getWidth(eliminationMsg)
    love.graphics.print(eliminationMsg, UIScale.centerX(eliminationWidth), yOffset)

    yOffset = yOffset + UIScale.scaleHeight(50)

    -- Top Player Stats
    local topStats = SeasonManager.getTopPlayerStats()
    if topStats.offensive or topStats.defensive then
        love.graphics.setFont(sectionFont)
        love.graphics.setColor(1, 0.9, 0.5)
        local statsHeader = "Season Leaders"
        local statsHeaderWidth = sectionFont:getWidth(statsHeader)
        love.graphics.print(statsHeader, UIScale.centerX(statsHeaderWidth), yOffset)

        yOffset = yOffset + UIScale.scaleHeight(40)

        love.graphics.setFont(recordFont)

        if topStats.offensive then
            love.graphics.setColor(0.3, 0.9, 0.3)
            local offText = string.format("Top Offensive: %s - %.1f yards, %d TDs",
                topStats.offensive.position or "Unknown",
                topStats.offensive.yardsGained or 0,
                topStats.offensive.touchdownsScored or 0)
            local offWidth = recordFont:getWidth(offText)
            love.graphics.print(offText, UIScale.centerX(offWidth), yOffset)

            yOffset = yOffset + UIScale.scaleHeight(30)
        end

        if topStats.defensive then
            love.graphics.setColor(0.9, 0.3, 0.3)
            local defText = string.format("Top Defensive: %s - %d slows, %d freezes",
                topStats.defensive.position or "Unknown",
                topStats.defensive.timesSlowed or 0,
                topStats.defensive.timesFroze or 0)
            local defWidth = recordFont:getWidth(defText)
            love.graphics.print(defText, UIScale.centerX(defWidth), yOffset)

            yOffset = yOffset + UIScale.scaleHeight(30)
        end
    end

    yOffset = yOffset + UIScale.scaleHeight(20)

    -- Button: "Simulate the Playoffs" or "View Bracket"
    local scaledButtonWidth = UIScale.scaleWidth(START_BUTTON_WIDTH)
    local scaledButtonHeight = UIScale.scaleHeight(START_BUTTON_HEIGHT)
    local buttonX = UIScale.centerX(scaledButtonWidth)
    local buttonY = yOffset

    local mx, my = love.mouse.getPosition()
    my = my - UIScale.scaleHeight(100)  -- Adjust for header
    local hoveringButton = mx >= buttonX and mx <= buttonX + scaledButtonWidth and
                          my >= buttonY and my <= buttonY + scaledButtonHeight

    -- Button background
    if ScoutingScreen.playoffsSimulated then
        -- View Bracket button (blue)
        if hoveringButton then
            love.graphics.setColor(0.4, 0.6, 0.9)
        else
            love.graphics.setColor(0.3, 0.5, 0.8)
        end
    else
        -- Simulate Playoffs button (green)
        if hoveringButton then
            love.graphics.setColor(0.4, 0.8, 0.5)
        else
            love.graphics.setColor(0.3, 0.7, 0.4)
        end
    end
    love.graphics.rectangle("fill", buttonX, buttonY, scaledButtonWidth, scaledButtonHeight)

    -- Button border
    if hoveringButton then
        love.graphics.setColor(0.6, 0.9, 1)
    else
        love.graphics.setColor(0.5, 0.7, 0.9)
    end
    love.graphics.setLineWidth(UIScale.scaleUniform(3))
    love.graphics.rectangle("line", buttonX, buttonY, scaledButtonWidth, scaledButtonHeight)

    -- Button text
    love.graphics.setFont(buttonFont)
    love.graphics.setColor(1, 1, 1)
    local buttonText = ScoutingScreen.playoffsSimulated and "View Bracket" or "Simulate the Playoffs"
    local buttonTextWidth = buttonFont:getWidth(buttonText)
    love.graphics.print(buttonText, buttonX + (scaledButtonWidth - buttonTextWidth) / 2, buttonY + UIScale.scaleHeight(15))
end

return ScoutingScreen
