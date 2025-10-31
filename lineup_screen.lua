--- lineup_screen.lua
--- Lineup Screen
---
--- Displays the player's full roster: 11 offensive starters, 11 defensive starters,
--- and bench slots (0-6 cards). Shows card details with tooltips on hover.
---
--- Dependencies: season_manager.lua, card.lua
--- Used by: season_menu.lua
--- LÖVE Callbacks: love.update, love.draw, love.mousepressed

local LineupScreen = {}

local SeasonManager = require("season_manager")
local Card = require("card")

-- State
LineupScreen.hoveredCard = nil  -- Card being hovered for tooltip
LineupScreen.selectedCard = nil  -- Card selected for swapping
LineupScreen.selectedCardLocation = nil  -- {section, index} where card is located
LineupScreen.contentHeight = 700

-- UI configuration
local CARD_WIDTH = 120
local CARD_HEIGHT = 80
local CARD_SPACING = 15
local SECTION_Y_OFFSET = 50
local CARDS_PER_ROW = 11

--- Initializes the lineup screen
function LineupScreen.load()
    LineupScreen.hoveredCard = nil
    LineupScreen.selectedCard = nil
    LineupScreen.selectedCardLocation = nil
end

--- LÖVE Callback: Update Logic
--- @param dt number Delta time in seconds
function LineupScreen.update(dt)
    -- Update hovered card
    local mx, my = love.mouse.getPosition()
    my = my - 100  -- Adjust for header

    local card, section, index = LineupScreen.getCardAtPosition(mx, my)
    LineupScreen.hoveredCard = card
end

--- LÖVE Callback: Draw UI
function LineupScreen.draw()
    if not SeasonManager.playerTeam then
        return
    end

    local yOffset = 20

    -- Offensive starters
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.setColor(0.3, 0.8, 0.3)
    love.graphics.print("Offensive Starters (11)", 50, yOffset)

    yOffset = yOffset + SECTION_Y_OFFSET
    LineupScreen.drawCardRow(SeasonManager.playerTeam.offensiveCards, yOffset, "offense")

    yOffset = yOffset + CARD_HEIGHT + 60

    -- Defensive starters
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.setColor(0.8, 0.3, 0.3)
    love.graphics.print("Defensive Starters (11)", 50, yOffset)

    yOffset = yOffset + SECTION_Y_OFFSET
    LineupScreen.drawCardRow(SeasonManager.playerTeam.defensiveCards, yOffset, "defense")

    yOffset = yOffset + CARD_HEIGHT + 60

    -- Bench
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.setColor(0.7, 0.7, 0.8)
    local benchCount = #SeasonManager.playerTeam.benchCards
    love.graphics.print(string.format("Bench (%d / 6)", benchCount), 50, yOffset)

    yOffset = yOffset + SECTION_Y_OFFSET
    if benchCount > 0 then
        LineupScreen.drawCardRow(SeasonManager.playerTeam.benchCards, yOffset, "bench")
    else
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.print("No bench cards yet. Purchase cards during training to fill your bench.", 50, yOffset)
    end

    -- Draw tooltip if hovering
    if LineupScreen.hoveredCard then
        LineupScreen.drawTooltip(LineupScreen.hoveredCard)
    end
end

--- Draws a row of cards
--- @param cards table Array of cards
--- @param y number Y position
--- @param section string Section identifier ("offense", "defense", "bench")
function LineupScreen.drawCardRow(cards, y, section)
    local mx, my = love.mouse.getPosition()
    my = my - 100  -- Adjust for header

    for i, card in ipairs(cards) do
        local x = 50 + ((i - 1) * (CARD_WIDTH + CARD_SPACING))
        LineupScreen.drawCard(card, x, y, mx, my, section, i)
    end
end

--- Draws a single card
--- @param card table The card data
--- @param x number X position
--- @param y number Y position
--- @param mx number Mouse X position
--- @param my number Mouse Y position
--- @param section string Section identifier (optional)
--- @param index number Card index in section (optional)
function LineupScreen.drawCard(card, x, y, mx, my, section, index)
    local hovering = mx >= x and mx <= x + CARD_WIDTH and
                    my >= y and my <= y + CARD_HEIGHT

    local isSelected = (LineupScreen.selectedCard == card)
    local canSwapWith = false

    -- Check if this card can be swapped with selected card
    if LineupScreen.selectedCard and not isSelected then
        canSwapWith = (LineupScreen.selectedCard.position == card.position)
    end

    -- Background
    if isSelected then
        love.graphics.setColor(0.4, 0.5, 0.3)  -- Green tint for selected
    elseif canSwapWith and hovering then
        love.graphics.setColor(0.3, 0.4, 0.5)  -- Blue tint for valid swap target
    elseif canSwapWith then
        love.graphics.setColor(0.25, 0.3, 0.35)  -- Subtle blue for swappable
    elseif hovering then
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

    -- Upgrade indicator
    if card.upgradeCount > 0 then
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.setColor(1, 0.8, 0.2)
        local upgradeText = string.format("+%d", card.upgradeCount)
        love.graphics.print(upgradeText, x + CARD_WIDTH - 35, y + 5)
    end

    -- Swap indicator for swappable cards
    if canSwapWith then
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.setColor(0.5, 0.8, 1)
        love.graphics.print("⇄", x + CARD_WIDTH - 28, y + CARD_HEIGHT - 30)
    end
end

--- Gets the card at the given mouse position
--- @param mx number Mouse X position
--- @param my number Mouse Y position
--- @return table|nil The card at the position, or nil
--- @return string|nil The section ("offense", "defense", "bench")
--- @return number|nil The index in the section
function LineupScreen.getCardAtPosition(mx, my)
    if not SeasonManager.playerTeam then
        return nil, nil, nil
    end

    local yOffset = 20 + SECTION_Y_OFFSET

    -- Check offensive cards
    for i, card in ipairs(SeasonManager.playerTeam.offensiveCards) do
        local x = 50 + ((i - 1) * (CARD_WIDTH + CARD_SPACING))
        if mx >= x and mx <= x + CARD_WIDTH and my >= yOffset and my <= yOffset + CARD_HEIGHT then
            return card, "offense", i
        end
    end

    yOffset = yOffset + CARD_HEIGHT + 60 + SECTION_Y_OFFSET

    -- Check defensive cards
    for i, card in ipairs(SeasonManager.playerTeam.defensiveCards) do
        local x = 50 + ((i - 1) * (CARD_WIDTH + CARD_SPACING))
        if mx >= x and mx <= x + CARD_WIDTH and my >= yOffset and my <= yOffset + CARD_HEIGHT then
            return card, "defense", i
        end
    end

    yOffset = yOffset + CARD_HEIGHT + 60 + SECTION_Y_OFFSET

    -- Check bench cards
    for i, card in ipairs(SeasonManager.playerTeam.benchCards) do
        local x = 50 + ((i - 1) * (CARD_WIDTH + CARD_SPACING))
        if mx >= x and mx <= x + CARD_WIDTH and my >= yOffset and my <= yOffset + CARD_HEIGHT then
            return card, "bench", i
        end
    end

    return nil, nil, nil
end

--- Draws a tooltip for a card
--- @param card table The card to show tooltip for
function LineupScreen.drawTooltip(card)
    local mx, my = love.mouse.getPosition()

    local tooltipWidth = 350
    local tooltipHeight = 0
    local padding = 15
    local lineHeight = 25

    -- Calculate tooltip height based on content
    local lines = 6  -- Base lines
    if card.cardType == Card.TYPE.YARD_GENERATOR then
        lines = lines + 2
    elseif card.cardType == Card.TYPE.BOOSTER then
        lines = lines + 2
    elseif card.cardType == Card.TYPE.DEFENDER then
        lines = lines + 2
    end

    tooltipHeight = (lines * lineHeight) + (padding * 2)

    -- Position tooltip to the right of mouse, or left if too close to edge
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
        love.graphics.print(string.format("Cooldown: %.2fs", card.cooldown), tooltipX + padding, contentY)
        contentY = contentY + lineHeight
    end

    -- Base stats (if upgraded)
    if card.upgradeCount > 0 then
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.print(string.format("Upgrades: %d / 3", card.upgradeCount), tooltipX + padding, contentY)
        contentY = contentY + lineHeight

        if card.yardsUpgrades > 0 then
            love.graphics.setColor(0.5, 0.8, 0.5)
            love.graphics.print(string.format("  Yards: +%.1f", card.yardsUpgrades * 0.5), tooltipX + padding, contentY)
            contentY = contentY + lineHeight
        end

        if card.cooldownUpgrades > 0 then
            love.graphics.setColor(0.5, 0.8, 0.8)
            local reduction = (1 - math.pow(0.9, card.cooldownUpgrades)) * 100
            love.graphics.print(string.format("  Speed: -%.0f%%", reduction), tooltipX + padding, contentY)
            contentY = contentY + lineHeight
        end
    else
        love.graphics.setColor(0.6, 0.6, 0.7)
        love.graphics.print("No upgrades", tooltipX + padding, contentY)
        contentY = contentY + lineHeight
    end
end

--- Swaps two cards between sections
--- @param section1 string First card's section
--- @param index1 number First card's index
--- @param section2 string Second card's section
--- @param index2 number Second card's index
function LineupScreen.swapCards(section1, index1, section2, index2)
    if not SeasonManager.playerTeam then
        return
    end

    -- Get the card arrays
    local array1 = nil
    local array2 = nil

    if section1 == "offense" then
        array1 = SeasonManager.playerTeam.offensiveCards
    elseif section1 == "defense" then
        array1 = SeasonManager.playerTeam.defensiveCards
    elseif section1 == "bench" then
        array1 = SeasonManager.playerTeam.benchCards
    end

    if section2 == "offense" then
        array2 = SeasonManager.playerTeam.offensiveCards
    elseif section2 == "defense" then
        array2 = SeasonManager.playerTeam.defensiveCards
    elseif section2 == "bench" then
        array2 = SeasonManager.playerTeam.benchCards
    end

    if not array1 or not array2 then
        return
    end

    -- Perform the swap
    local temp = array1[index1]
    array1[index1] = array2[index2]
    array2[index2] = temp
end

--- LÖVE Callback: Mouse Pressed
--- @param x number Mouse X position
--- @param y number Mouse Y position
--- @param button number Mouse button
function LineupScreen.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    local card, section, index = LineupScreen.getCardAtPosition(x, y)

    if not card then
        -- Clicked empty space - deselect
        LineupScreen.selectedCard = nil
        LineupScreen.selectedCardLocation = nil
        return
    end

    -- If no card selected, select this one
    if not LineupScreen.selectedCard then
        LineupScreen.selectedCard = card
        LineupScreen.selectedCardLocation = {section = section, index = index}
        return
    end

    -- If clicking the same card, deselect
    if LineupScreen.selectedCard == card then
        LineupScreen.selectedCard = nil
        LineupScreen.selectedCardLocation = nil
        return
    end

    -- Check if cards can be swapped (same position)
    if LineupScreen.selectedCard.position == card.position then
        LineupScreen.swapCards(
            LineupScreen.selectedCardLocation.section,
            LineupScreen.selectedCardLocation.index,
            section,
            index
        )
        LineupScreen.selectedCard = nil
        LineupScreen.selectedCardLocation = nil
    else
        -- Different position - select the new card instead
        LineupScreen.selectedCard = card
        LineupScreen.selectedCardLocation = {section = section, index = index}
    end
end

return LineupScreen
