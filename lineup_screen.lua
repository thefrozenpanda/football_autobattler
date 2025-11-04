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
local UIScale = require("ui_scale")

-- State
LineupScreen.hoveredCard = nil  -- Card being hovered for tooltip
LineupScreen.selectedCard = nil  -- Card selected for swapping
LineupScreen.selectedCardLocation = nil  -- {section, index} where card is located
LineupScreen.contentHeight = 700

-- UI configuration (base values for 1600x900)
local CARD_WIDTH = 120
local CARD_HEIGHT = 80
local CARD_SPACING = 15
local SECTION_Y_OFFSET = 50
local CARDS_PER_ROW = 11

-- Fonts
local sectionFont
local benchMessageFont
local cardPositionFont
local cardNumberFont
local upgradeFont
local swapIconFont
local tooltipHeaderFont
local tooltipTextFont

--- Initializes the lineup screen
function LineupScreen.load()
    -- Update UI scale
    UIScale.update()

    -- Create fonts
    sectionFont = love.graphics.newFont(UIScale.scaleFontSize(28))
    benchMessageFont = love.graphics.newFont(UIScale.scaleFontSize(20))
    cardPositionFont = love.graphics.newFont(UIScale.scaleFontSize(20))
    cardNumberFont = love.graphics.newFont(UIScale.scaleFontSize(28))
    upgradeFont = love.graphics.newFont(UIScale.scaleFontSize(16))
    swapIconFont = love.graphics.newFont(UIScale.scaleFontSize(24))
    tooltipHeaderFont = love.graphics.newFont(UIScale.scaleFontSize(22))
    tooltipTextFont = love.graphics.newFont(UIScale.scaleFontSize(18))

    LineupScreen.hoveredCard = nil
    LineupScreen.selectedCard = nil
    LineupScreen.selectedCardLocation = nil
end

--- LÖVE Callback: Update Logic
--- @param dt number Delta time in seconds
function LineupScreen.update(dt)
    -- Update hovered card
    local mx, my = love.mouse.getPosition()
    my = my - UIScale.scaleHeight(100)  -- Adjust for header

    local card, section, index = LineupScreen.getCardAtPosition(mx, my)
    LineupScreen.hoveredCard = card
end

--- LÖVE Callback: Draw UI
function LineupScreen.draw()
    if not SeasonManager.playerTeam then
        return
    end

    local yOffset = UIScale.scaleY(20)
    local startX = UIScale.scaleX(50)

    -- Offensive starters
    love.graphics.setFont(sectionFont)
    love.graphics.setColor(0.3, 0.8, 0.3)
    love.graphics.print("Offensive Starters (11)", startX, yOffset)

    yOffset = yOffset + UIScale.scaleHeight(SECTION_Y_OFFSET)
    LineupScreen.drawCardRow(SeasonManager.playerTeam.offensiveCards, yOffset, "offense")

    yOffset = yOffset + UIScale.scaleHeight(CARD_HEIGHT + 60)

    -- Defensive starters
    love.graphics.setFont(sectionFont)
    love.graphics.setColor(0.8, 0.3, 0.3)
    love.graphics.print("Defensive Starters (11)", startX, yOffset)

    yOffset = yOffset + UIScale.scaleHeight(SECTION_Y_OFFSET)
    LineupScreen.drawCardRow(SeasonManager.playerTeam.defensiveCards, yOffset, "defense")

    yOffset = yOffset + UIScale.scaleHeight(CARD_HEIGHT + 60)

    -- Special Teams
    love.graphics.setFont(sectionFont)
    love.graphics.setColor(0.4, 0.9, 0.4)
    love.graphics.print("Special Teams (2)", startX, yOffset)

    yOffset = yOffset + UIScale.scaleHeight(SECTION_Y_OFFSET)
    local specialTeamsCards = {}
    if SeasonManager.playerTeam.kicker then
        table.insert(specialTeamsCards, SeasonManager.playerTeam.kicker)
    end
    if SeasonManager.playerTeam.punter then
        table.insert(specialTeamsCards, SeasonManager.playerTeam.punter)
    end
    LineupScreen.drawCardRow(specialTeamsCards, yOffset, "special_teams")

    yOffset = yOffset + UIScale.scaleHeight(CARD_HEIGHT + 60)

    -- Bench
    love.graphics.setFont(sectionFont)
    love.graphics.setColor(0.7, 0.7, 0.8)
    local benchCount = #SeasonManager.playerTeam.benchCards
    love.graphics.print(string.format("Bench (%d / 6)", benchCount), startX, yOffset)

    yOffset = yOffset + UIScale.scaleHeight(SECTION_Y_OFFSET)
    if benchCount > 0 then
        LineupScreen.drawCardRow(SeasonManager.playerTeam.benchCards, yOffset, "bench")
    else
        love.graphics.setFont(benchMessageFont)
        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.print("No bench cards yet. Purchase cards during training to fill your bench.", startX, yOffset)
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
    my = my - UIScale.scaleHeight(100)  -- Adjust for header

    local scaledCardWidth = UIScale.scaleWidth(CARD_WIDTH)
    local scaledCardSpacing = UIScale.scaleUniform(CARD_SPACING)
    local startX = UIScale.scaleX(50)

    for i, card in ipairs(cards) do
        local x = startX + ((i - 1) * (scaledCardWidth + scaledCardSpacing))
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
    local scaledCardWidth = UIScale.scaleWidth(CARD_WIDTH)
    local scaledCardHeight = UIScale.scaleHeight(CARD_HEIGHT)

    local hovering = mx >= x and mx <= x + scaledCardWidth and
                    my >= y and my <= y + scaledCardHeight

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

    -- Upgrade indicator (bronze/silver/gold circle)
    if card.upgradeCount > 0 then
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

    -- Swap indicator for swappable cards
    if canSwapWith then
        love.graphics.setFont(swapIconFont)
        love.graphics.setColor(0.5, 0.8, 1)
        love.graphics.print("⇄", x + scaledCardWidth - UIScale.scaleUniform(28), y + scaledCardHeight - UIScale.scaleHeight(30))
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

    local scaledCardWidth = UIScale.scaleWidth(CARD_WIDTH)
    local scaledCardHeight = UIScale.scaleHeight(CARD_HEIGHT)
    local scaledCardSpacing = UIScale.scaleUniform(CARD_SPACING)
    local startX = UIScale.scaleX(50)
    local yOffset = UIScale.scaleY(20) + UIScale.scaleHeight(SECTION_Y_OFFSET)

    -- Check offensive cards
    for i, card in ipairs(SeasonManager.playerTeam.offensiveCards) do
        local x = startX + ((i - 1) * (scaledCardWidth + scaledCardSpacing))
        if mx >= x and mx <= x + scaledCardWidth and my >= yOffset and my <= yOffset + scaledCardHeight then
            return card, "offense", i
        end
    end

    yOffset = yOffset + UIScale.scaleHeight(CARD_HEIGHT + 60 + SECTION_Y_OFFSET)

    -- Check defensive cards
    for i, card in ipairs(SeasonManager.playerTeam.defensiveCards) do
        local x = startX + ((i - 1) * (scaledCardWidth + scaledCardSpacing))
        if mx >= x and mx <= x + scaledCardWidth and my >= yOffset and my <= yOffset + scaledCardHeight then
            return card, "defense", i
        end
    end

    yOffset = yOffset + UIScale.scaleHeight(CARD_HEIGHT + 60 + SECTION_Y_OFFSET)

    -- Check bench cards
    for i, card in ipairs(SeasonManager.playerTeam.benchCards) do
        local x = startX + ((i - 1) * (scaledCardWidth + scaledCardSpacing))
        if mx >= x and mx <= x + scaledCardWidth and my >= yOffset and my <= yOffset + scaledCardHeight then
            return card, "bench", i
        end
    end

    return nil, nil, nil
end

--- Draws a tooltip for a card
--- @param card table The card to show tooltip for
function LineupScreen.drawTooltip(card)
    local mx, my = love.mouse.getPosition()

    local tooltipWidth = UIScale.scaleWidth(350)
    local tooltipHeight = 0
    local padding = UIScale.scaleUniform(15)
    local lineHeight = UIScale.scaleHeight(25)

    -- Calculate tooltip height based on content
    local lines = 6  -- Base lines
    if card.cardType == Card.TYPE.YARD_GENERATOR then
        lines = lines + 2
    elseif card.cardType == Card.TYPE.BOOSTER then
        lines = lines + 2
    elseif card.cardType == Card.TYPE.DEFENDER then
        lines = lines + 2
    elseif card.cardType == Card.TYPE.KICKER then
        lines = lines + 2
    elseif card.cardType == Card.TYPE.PUNTER then
        lines = lines + 2
    end

    tooltipHeight = (lines * lineHeight) + (padding * 2)

    -- Position tooltip to the right of mouse, or left if too close to edge
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
    contentY = contentY + lineHeight + UIScale.scaleHeight(5)

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

    -- Upgrade tier (if upgraded)
    if card.upgradeCount > 0 then
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
        love.graphics.print(string.format("Tier: %s (%d / 3)", tierName, card.upgradeCount), tooltipX + padding, contentY)
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

    -- Adjust for header
    local adjustedY = y - UIScale.scaleHeight(100)

    local card, section, index = LineupScreen.getCardAtPosition(x, adjustedY)

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
