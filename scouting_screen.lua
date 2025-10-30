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

-- State
ScoutingScreen.opponent = nil
ScoutingScreen.matchData = nil
ScoutingScreen.hoveredCard = nil
ScoutingScreen.startMatchRequested = false
ScoutingScreen.contentHeight = 700

-- UI configuration
local CARD_WIDTH = 120
local CARD_HEIGHT = 80
local CARD_SPACING = 15
local SECTION_Y_OFFSET = 50
local START_BUTTON_WIDTH = 250
local START_BUTTON_HEIGHT = 60

--- Initializes the scouting screen
function ScoutingScreen.load()
    ScoutingScreen.hoveredCard = nil
    ScoutingScreen.startMatchRequested = false

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
    my = my - 100  -- Adjust for header

    ScoutingScreen.hoveredCard = ScoutingScreen.getCardAtPosition(mx, my)
end

--- LÖVE Callback: Draw UI
function ScoutingScreen.draw()
    if not ScoutingScreen.opponent then
        -- No upcoming match
        love.graphics.setFont(love.graphics.newFont(28))
        love.graphics.setColor(0.8, 0.8, 0.9)
        local noMatchText = "No upcoming match. Season may be complete."
        local textWidth = love.graphics.getFont():getWidth(noMatchText)
        love.graphics.print(noMatchText, (1600 - textWidth) / 2, 300)
        return
    end

    local yOffset = 20

    -- Title
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Next Match Scouting Report", 50, yOffset)

    yOffset = yOffset + 50

    -- Matchup info
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(0.8, 0.9, 1)

    local matchupText = ""
    if ScoutingScreen.matchData.isHome then
        matchupText = string.format("%s vs %s (Home)", SeasonManager.playerTeam.name, ScoutingScreen.opponent.name)
    else
        matchupText = string.format("%s @ %s (Away)", SeasonManager.playerTeam.name, ScoutingScreen.opponent.name)
    end
    love.graphics.print(matchupText, 50, yOffset)

    yOffset = yOffset + 40

    -- Opponent record
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(0.7, 0.7, 0.8)
    local recordText = string.format("Opponent Record: %s", ScoutingScreen.opponent:getRecordString())
    love.graphics.print(recordText, 50, yOffset)

    yOffset = yOffset + 50

    -- Offensive cards
    love.graphics.setFont(love.graphics.newFont(26))
    love.graphics.setColor(0.3, 0.8, 0.3)
    love.graphics.print("Opponent Offense", 50, yOffset)

    yOffset = yOffset + SECTION_Y_OFFSET
    ScoutingScreen.drawCardRow(ScoutingScreen.opponent.offensiveCards, yOffset)

    yOffset = yOffset + CARD_HEIGHT + 60

    -- Defensive cards
    love.graphics.setFont(love.graphics.newFont(26))
    love.graphics.setColor(0.8, 0.3, 0.3)
    love.graphics.print("Opponent Defense", 50, yOffset)

    yOffset = yOffset + SECTION_Y_OFFSET
    ScoutingScreen.drawCardRow(ScoutingScreen.opponent.defensiveCards, yOffset)

    -- Start Match button
    local buttonX = (1600 - START_BUTTON_WIDTH) / 2
    local buttonY = ScoutingScreen.contentHeight - START_BUTTON_HEIGHT - 30

    local mx, my = love.mouse.getPosition()
    my = my - 100  -- Adjust for header
    local hoveringButton = mx >= buttonX and mx <= buttonX + START_BUTTON_WIDTH and
                          my >= buttonY and my <= buttonY + START_BUTTON_HEIGHT

    -- Button
    if hoveringButton then
        love.graphics.setColor(0.3, 0.6, 0.3)
    else
        love.graphics.setColor(0.2, 0.5, 0.2)
    end
    love.graphics.rectangle("fill", buttonX, buttonY, START_BUTTON_WIDTH, START_BUTTON_HEIGHT)

    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", buttonX, buttonY, START_BUTTON_WIDTH, START_BUTTON_HEIGHT)

    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.setColor(1, 1, 1)
    local buttonText = "Start Match"
    local buttonTextWidth = love.graphics.getFont():getWidth(buttonText)
    love.graphics.print(buttonText, buttonX + (START_BUTTON_WIDTH - buttonTextWidth) / 2, buttonY + 15)

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
    my = my - 100  -- Adjust for header

    for i, card in ipairs(cards) do
        local x = 50 + ((i - 1) * (CARD_WIDTH + CARD_SPACING))
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
    local hovering = mx >= x and mx <= x + CARD_WIDTH and
                    my >= y and my <= y + CARD_HEIGHT

    -- Background
    if hovering then
        love.graphics.setColor(0.3, 0.35, 0.4)
    else
        love.graphics.setColor(0.2, 0.2, 0.25)
    end
    love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT)

    -- Border
    if card.cardType == Card.TYPE.YARD_GENERATOR then
        love.graphics.setColor(0.3, 0.7, 0.3)
    elseif card.cardType == Card.TYPE.BOOSTER then
        love.graphics.setColor(0.3, 0.5, 0.8)
    elseif card.cardType == Card.TYPE.DEFENDER then
        love.graphics.setColor(0.8, 0.3, 0.3)
    end
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT)

    -- Position and number
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(card.position, x + 10, y + 10)

    love.graphics.setFont(love.graphics.newFont(28))
    local numText = string.format("#%d", card.number)
    love.graphics.print(numText, x + 10, y + 35)
end

--- Gets the card at the given mouse position
--- @param mx number Mouse X position
--- @param my number Mouse Y position
--- @return table|nil The card at the position, or nil
function ScoutingScreen.getCardAtPosition(mx, my)
    if not ScoutingScreen.opponent then
        return nil
    end

    local yOffset = 20 + 50 + 40 + 50 + SECTION_Y_OFFSET

    -- Check offensive cards
    for i, card in ipairs(ScoutingScreen.opponent.offensiveCards) do
        local x = 50 + ((i - 1) * (CARD_WIDTH + CARD_SPACING))
        if mx >= x and mx <= x + CARD_WIDTH and my >= yOffset and my <= yOffset + CARD_HEIGHT then
            return card
        end
    end

    yOffset = yOffset + CARD_HEIGHT + 60 + SECTION_Y_OFFSET

    -- Check defensive cards
    for i, card in ipairs(ScoutingScreen.opponent.defensiveCards) do
        local x = 50 + ((i - 1) * (CARD_WIDTH + CARD_SPACING))
        if mx >= x and mx <= x + CARD_WIDTH and my >= yOffset and my <= yOffset + CARD_HEIGHT then
            return card
        end
    end

    return nil
end

--- Draws a tooltip for a card
--- @param card table The card to show tooltip for
function ScoutingScreen.drawTooltip(card)
    local mx, my = love.mouse.getPosition()

    local tooltipWidth = 300
    local tooltipHeight = 0
    local padding = 15
    local lineHeight = 25

    -- Calculate tooltip height
    local lines = 5
    if card.cardType == Card.TYPE.YARD_GENERATOR then
        lines = lines + 2
    elseif card.cardType == Card.TYPE.BOOSTER then
        lines = lines + 2
    elseif card.cardType == Card.TYPE.DEFENDER then
        lines = lines + 3
    end

    tooltipHeight = (lines * lineHeight) + (padding * 2)

    -- Position tooltip
    local tooltipX = mx + 15
    local tooltipY = my - tooltipHeight / 2

    if tooltipX + tooltipWidth > 1600 then
        tooltipX = mx - tooltipWidth - 15
    end

    if tooltipY < 0 then
        tooltipY = 0
    end
    if tooltipY + tooltipHeight > 900 then
        tooltipY = 900 - tooltipHeight
    end

    -- Background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
    love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipWidth, tooltipHeight)

    -- Border
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", tooltipX, tooltipY, tooltipWidth, tooltipHeight)

    -- Content
    local contentY = tooltipY + padding
    love.graphics.setFont(love.graphics.newFont(22))

    -- Position and number
    love.graphics.setColor(1, 1, 1)
    local headerText = string.format("%s #%d", card.position, card.number)
    love.graphics.print(headerText, tooltipX + padding, contentY)
    contentY = contentY + lineHeight

    -- Type
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(0.8, 0.8, 0.9)
    local typeText = ""
    if card.cardType == Card.TYPE.YARD_GENERATOR then
        typeText = "Yard Generator"
    elseif card.cardType == Card.TYPE.BOOSTER then
        typeText = "Booster"
    elseif card.cardType == Card.TYPE.DEFENDER then
        typeText = "Defender"
    end
    love.graphics.print(typeText, tooltipX + padding, contentY)
    contentY = contentY + lineHeight + 5

    -- Stats
    love.graphics.setColor(0.9, 0.9, 1)

    if card.cardType == Card.TYPE.YARD_GENERATOR then
        love.graphics.print(string.format("Yards: %.1f", card.yardsPerAction), tooltipX + padding, contentY)
        contentY = contentY + lineHeight
        love.graphics.print(string.format("Cooldown: %.2fs", card.cooldown), tooltipX + padding, contentY)
        contentY = contentY + lineHeight

    elseif card.cardType == Card.TYPE.BOOSTER then
        love.graphics.print(string.format("Boost: +%d%%", card.boostAmount), tooltipX + padding, contentY)
        contentY = contentY + lineHeight
        love.graphics.print(string.format("Cooldown: %.2fs", card.cooldown), tooltipX + padding, contentY)
        contentY = contentY + lineHeight

    elseif card.cardType == Card.TYPE.DEFENDER then
        love.graphics.print(string.format("Effect: %s", card.effectType), tooltipX + padding, contentY)
        contentY = contentY + lineHeight
        love.graphics.print(string.format("Strength: %.1f", card.effectStrength), tooltipX + padding, contentY)
        contentY = contentY + lineHeight
        love.graphics.print(string.format("Cooldown: %.2fs", card.cooldown), tooltipX + padding, contentY)
        contentY = contentY + lineHeight
    end
end

--- LÖVE Callback: Mouse Pressed
--- @param x number Mouse X position
--- @param y number Mouse Y position
--- @param button number Mouse button
function ScoutingScreen.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    -- Check Start Match button
    local buttonX = (1600 - START_BUTTON_WIDTH) / 2
    local buttonY = ScoutingScreen.contentHeight - START_BUTTON_HEIGHT - 30

    if x >= buttonX and x <= buttonX + START_BUTTON_WIDTH and
       y >= buttonY and y <= buttonY + START_BUTTON_HEIGHT then
        ScoutingScreen.startMatchRequested = true
    end
end

--- Checks if start match was requested
--- @return boolean True if button clicked
function ScoutingScreen.isStartMatchRequested()
    return ScoutingScreen.startMatchRequested
end

return ScoutingScreen
