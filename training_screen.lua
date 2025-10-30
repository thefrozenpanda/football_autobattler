--- training_screen.lua
--- Training Screen
---
--- Displays 3 random upgrade options per week.
--- Options: Upgrade yards (+0.5 for 50 cash), Upgrade cooldown (-10% for 75 cash),
---          New bench card (200 cash)
--- Players can purchase any or all options if they have sufficient cash.
---
--- Dependencies: season_manager.lua, card.lua, coach.lua
--- Used by: season_menu.lua
--- LÖVE Callbacks: love.update, love.draw, love.mousepressed

local TrainingScreen = {}

local SeasonManager = require("season_manager")
local Card = require("card")
local Coach = require("coach")

-- State
TrainingScreen.upgradeOptions = {}  -- 3 random upgrade options
TrainingScreen.contentHeight = 700  -- Available height for content

-- UI configuration
local OPTION_WIDTH = 450
local OPTION_HEIGHT = 220
local OPTION_SPACING = 50
local START_Y = 100

--- Upgrade option types
local UPGRADE_TYPE = {
    YARDS = "yards",
    COOLDOWN = "cooldown",
    BENCH_CARD = "bench_card"
}

--- Initializes the training screen
--- Generates 3 random upgrade options
function TrainingScreen.load()
    TrainingScreen.upgradeOptions = {}
    TrainingScreen.generateUpgradeOptions()
end

--- Generates 3 random upgrade options for the week
function TrainingScreen.generateUpgradeOptions()
    if not SeasonManager.playerTeam then
        return
    end

    local options = {}

    -- Get all upgradeable cards (offensive + defensive)
    local upgradeableCards = {}
    for _, card in ipairs(SeasonManager.playerTeam.offensiveCards) do
        if card:canUpgrade() then
            table.insert(upgradeableCards, card)
        end
    end
    for _, card in ipairs(SeasonManager.playerTeam.defensiveCards) do
        if card:canUpgrade() then
            table.insert(upgradeableCards, card)
        end
    end

    -- Generate 2 card upgrade options (if possible)
    local upgradeTypes = {UPGRADE_TYPE.YARDS, UPGRADE_TYPE.COOLDOWN}

    for i = 1, 2 do
        if #upgradeableCards > 0 then
            local cardIndex = math.random(1, #upgradeableCards)
            local card = upgradeableCards[cardIndex]
            local upgradeType = upgradeTypes[math.random(1, #upgradeTypes)]

            -- Only offer yards upgrade for yard generators
            if upgradeType == UPGRADE_TYPE.YARDS and card.cardType ~= Card.TYPE.YARD_GENERATOR then
                upgradeType = UPGRADE_TYPE.COOLDOWN
            end

            table.insert(options, {
                type = upgradeType,
                card = card,
                cost = upgradeType == UPGRADE_TYPE.YARDS and Card.getYardsUpgradeCost() or Card.getCooldownUpgradeCost()
            })

            -- Remove card from available pool to avoid duplicates
            table.remove(upgradeableCards, cardIndex)
        end
    end

    -- Third option: New bench card
    local availableCoaches = Coach.types
    local randomCoach = availableCoaches[math.random(1, #availableCoaches)]

    -- Pick random card from coach's offensive cards
    local randomCardData = randomCoach.offensiveCards[math.random(1, #randomCoach.offensiveCards)]

    -- Create new card instance
    local newCard = Card:new(randomCardData.position, randomCardData.cardType, {
        yardsPerAction = randomCardData.yardsPerAction or 0,
        boostAmount = randomCardData.boostAmount or 0,
        boostTargets = randomCardData.boostTargets or {},
        effectType = randomCardData.effectType or nil,
        effectStrength = randomCardData.effectStrength or 0,
        targetPositions = randomCardData.targetPositions or {},
        speed = randomCardData.speed or 1.5
    })

    table.insert(options, {
        type = UPGRADE_TYPE.BENCH_CARD,
        card = newCard,
        cost = Card.getBenchCardCost()
    })

    TrainingScreen.upgradeOptions = options
end

--- LÖVE Callback: Update Logic
--- @param dt number Delta time in seconds
function TrainingScreen.update(dt)
    -- Nothing to update currently
end

--- LÖVE Callback: Draw UI
function TrainingScreen.draw()
    -- Title
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.setColor(1, 1, 1)
    local titleText = "Training Week - Choose Upgrades"
    local titleWidth = love.graphics.getFont():getWidth(titleText)
    love.graphics.print(titleText, (1600 - titleWidth) / 2, 20)

    -- Draw upgrade options
    local totalWidth = (#TrainingScreen.upgradeOptions * OPTION_WIDTH) + ((#TrainingScreen.upgradeOptions - 1) * OPTION_SPACING)
    local startX = (1600 - totalWidth) / 2

    local mx, my = love.mouse.getPosition()
    my = my - 100  -- Adjust for header

    for i, option in ipairs(TrainingScreen.upgradeOptions) do
        local optionX = startX + ((i - 1) * (OPTION_WIDTH + OPTION_SPACING))
        local optionY = START_Y

        TrainingScreen.drawUpgradeOption(option, optionX, optionY, mx, my)
    end

    -- Instructions
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(0.7, 0.7, 0.8)
    local instructText = "Click on an upgrade to purchase it. You can buy multiple upgrades if you have enough cash."
    local instructWidth = love.graphics.getFont():getWidth(instructText)
    love.graphics.print(instructText, (1600 - instructWidth) / 2, START_Y + OPTION_HEIGHT + 50)
end

--- Draws a single upgrade option
--- @param option table The upgrade option data
--- @param x number X position
--- @param y number Y position
--- @param mx number Mouse X position
--- @param my number Mouse Y position
function TrainingScreen.drawUpgradeOption(option, x, y, mx, my)
    local hovering = mx >= x and mx <= x + OPTION_WIDTH and
                    my >= y and my <= y + OPTION_HEIGHT

    local canAfford = SeasonManager.playerTeam and SeasonManager.playerTeam.cash >= option.cost

    -- Background
    if hovering and canAfford then
        love.graphics.setColor(0.25, 0.3, 0.35)
    else
        love.graphics.setColor(0.2, 0.2, 0.25)
    end
    love.graphics.rectangle("fill", x, y, OPTION_WIDTH, OPTION_HEIGHT)

    -- Border
    if canAfford then
        love.graphics.setColor(0.4, 0.5, 0.6)
    else
        love.graphics.setColor(0.3, 0.3, 0.35)
    end
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", x, y, OPTION_WIDTH, OPTION_HEIGHT)

    -- Content
    local contentY = y + 15

    -- Upgrade type header
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(0.8, 0.9, 1)

    local headerText = ""
    if option.type == UPGRADE_TYPE.YARDS then
        headerText = "Upgrade Yards"
    elseif option.type == UPGRADE_TYPE.COOLDOWN then
        headerText = "Upgrade Speed"
    elseif option.type == UPGRADE_TYPE.BENCH_CARD then
        headerText = "New Bench Card"
    end

    love.graphics.print(headerText, x + 15, contentY)
    contentY = contentY + 35

    -- Card info
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(1, 1, 1)

    local cardText = string.format("#%d %s", option.card.number, option.card.position)
    love.graphics.print(cardText, x + 15, contentY)
    contentY = contentY + 30

    -- Current stats
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(0.8, 0.8, 0.9)

    if option.type == UPGRADE_TYPE.YARDS then
        local currentYards = string.format("Current: %.1f yards", option.card.yardsPerAction)
        love.graphics.print(currentYards, x + 15, contentY)
        contentY = contentY + 25

        love.graphics.setColor(0.3, 0.8, 0.3)
        local newYards = string.format("New: %.1f yards (+0.5)", option.card.yardsPerAction + 0.5)
        love.graphics.print(newYards, x + 15, contentY)

    elseif option.type == UPGRADE_TYPE.COOLDOWN then
        local currentCooldown = string.format("Current: %.2fs cooldown", option.card.cooldown)
        love.graphics.print(currentCooldown, x + 15, contentY)
        contentY = contentY + 25

        love.graphics.setColor(0.3, 0.8, 0.3)
        local newCooldown = string.format("New: %.2fs (-10%%)", option.card.cooldown * 0.9)
        love.graphics.print(newCooldown, x + 15, contentY)

    elseif option.type == UPGRADE_TYPE.BENCH_CARD then
        local cardInfo = ""
        if option.card.cardType == Card.TYPE.YARD_GENERATOR then
            cardInfo = string.format("%.1f yards / %.2fs", option.card.yardsPerAction, option.card.cooldown)
        elseif option.card.cardType == Card.TYPE.BOOSTER then
            cardInfo = string.format("+%d%% boost / %.2fs", option.card.boostAmount, option.card.cooldown)
        elseif option.card.cardType == Card.TYPE.DEFENDER then
            cardInfo = string.format("%s / %.2fs", option.card.effectType, option.card.cooldown)
        end
        love.graphics.print(cardInfo, x + 15, contentY)
    end

    -- Upgrade count (for existing cards)
    if option.type ~= UPGRADE_TYPE.BENCH_CARD then
        contentY = contentY + 30
        love.graphics.setColor(0.7, 0.7, 0.8)
        local upgradeText = string.format("Upgrades: %d / 3", option.card.upgradeCount)
        love.graphics.print(upgradeText, x + 15, contentY)
    end

    -- Cost
    contentY = y + OPTION_HEIGHT - 50
    love.graphics.setFont(love.graphics.newFont(22))

    if canAfford then
        love.graphics.setColor(0.3, 0.8, 0.3)
    else
        love.graphics.setColor(0.8, 0.3, 0.3)
    end

    local costText = string.format("Cost: $%d", option.cost)
    love.graphics.print(costText, x + 15, contentY)

    -- Purchase button
    if canAfford then
        love.graphics.setColor(0.2, 0.6, 0.2)
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
    end

    local btnWidth = 120
    local btnHeight = 35
    local btnX = x + OPTION_WIDTH - btnWidth - 15
    local btnY = contentY - 5

    love.graphics.rectangle("fill", btnX, btnY, btnWidth, btnHeight)

    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", btnX, btnY, btnWidth, btnHeight)

    love.graphics.setFont(love.graphics.newFont(20))
    if canAfford then
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
    end

    local buyText = "Purchase"
    local buyWidth = love.graphics.getFont():getWidth(buyText)
    love.graphics.print(buyText, btnX + (btnWidth - buyWidth) / 2, btnY + 5)
end

--- LÖVE Callback: Mouse Pressed
--- @param x number Mouse X position
--- @param y number Mouse Y position
--- @param button number Mouse button
function TrainingScreen.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    -- Calculate positions
    local totalWidth = (#TrainingScreen.upgradeOptions * OPTION_WIDTH) + ((#TrainingScreen.upgradeOptions - 1) * OPTION_SPACING)
    local startX = (1600 - totalWidth) / 2

    -- Check each option
    for i, option in ipairs(TrainingScreen.upgradeOptions) do
        local optionX = startX + ((i - 1) * (OPTION_WIDTH + OPTION_SPACING))
        local optionY = START_Y

        if x >= optionX and x <= optionX + OPTION_WIDTH and
           y >= optionY and y <= optionY + OPTION_HEIGHT then
            TrainingScreen.purchaseUpgrade(option, i)
            return
        end
    end
end

--- Purchases an upgrade
--- @param option table The upgrade option
--- @param index number The option index in the array
function TrainingScreen.purchaseUpgrade(option, index)
    if not SeasonManager.playerTeam then
        return
    end

    -- Check if player can afford
    if not SeasonManager.playerTeam:spendCash(option.cost) then
        return  -- Not enough cash
    end

    -- Apply upgrade
    if option.type == UPGRADE_TYPE.YARDS then
        option.card:upgradeYards()
    elseif option.type == UPGRADE_TYPE.COOLDOWN then
        option.card:upgradeCooldown()
    elseif option.type == UPGRADE_TYPE.BENCH_CARD then
        -- Add to bench
        table.insert(SeasonManager.playerTeam.benchCards, option.card)
    end

    -- Remove this option
    table.remove(TrainingScreen.upgradeOptions, index)

    -- If all options purchased, generate new ones
    if #TrainingScreen.upgradeOptions == 0 then
        TrainingScreen.generateUpgradeOptions()
    end
end

return TrainingScreen
