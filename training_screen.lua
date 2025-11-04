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
local UIScale = require("ui_scale")

-- State
TrainingScreen.upgradeOptions = {}  -- 3 random upgrade options
TrainingScreen.contentHeight = 700  -- Available height for content

-- UI configuration (base values for 1600x900)
local OPTION_WIDTH = 450
local OPTION_HEIGHT = 220
local OPTION_SPACING = 50
local START_Y = 100

-- Fonts
local titleFont
local headerFont
local cardFont
local statsFont
local costFont
local buttonFont
local instructFont

--- Upgrade option types
local UPGRADE_TYPE = {
    YARDS = "yards",
    COOLDOWN = "cooldown",
    BOOST = "boost",
    DURATION = "duration",
    BONUS_YARDS = "bonus_yards",
    IMMUNITY = "immunity",
    BENCH_CARD = "bench_card",
    KICKER_RANGE = "kicker_range",
    KICKER_ACCURACY = "kicker_accuracy",
    PUNTER_RANGE = "punter_range"
}

--- Initializes the training screen
--- Generates 3 random upgrade options (only if not already generated for this week)
function TrainingScreen.load()
    -- Update UI scale
    UIScale.update()

    -- Create fonts
    titleFont = love.graphics.newFont(UIScale.scaleFontSize(32))
    headerFont = love.graphics.newFont(UIScale.scaleFontSize(24))
    cardFont = love.graphics.newFont(UIScale.scaleFontSize(20))
    statsFont = love.graphics.newFont(UIScale.scaleFontSize(18))
    costFont = love.graphics.newFont(UIScale.scaleFontSize(22))
    buttonFont = love.graphics.newFont(UIScale.scaleFontSize(20))
    instructFont = love.graphics.newFont(UIScale.scaleFontSize(20))

    -- Check if options already exist in SeasonManager for this week
    if SeasonManager.weeklyUpgradeOptions and #SeasonManager.weeklyUpgradeOptions > 0 then
        -- Use existing options (locked for the week)
        TrainingScreen.upgradeOptions = SeasonManager.weeklyUpgradeOptions
    else
        -- Generate new options and store them
        TrainingScreen.upgradeOptions = {}
        TrainingScreen.generateUpgradeOptions()
        SeasonManager.weeklyUpgradeOptions = TrainingScreen.upgradeOptions
    end
end

--- Generates 3 random upgrade options for the week
function TrainingScreen.generateUpgradeOptions()
    if not SeasonManager.playerTeam then
        return
    end

    local options = {}

    -- Get all upgradeable cards (offensive + defensive + special teams)
    local upgradeableCards = {}
    for _, card in ipairs(SeasonManager.playerTeam.offensiveCards) do
        if card:canUpgrade() or (not card.hasImmunity and card.upgradeCount <= 1) then
            table.insert(upgradeableCards, card)
        end
    end
    for _, card in ipairs(SeasonManager.playerTeam.defensiveCards) do
        if card:canUpgrade() or (not card.hasImmunity and card.upgradeCount <= 1) then
            table.insert(upgradeableCards, card)
        end
    end
    -- Add special teams cards
    if SeasonManager.playerTeam.kicker and SeasonManager.playerTeam.kicker:canUpgrade() then
        table.insert(upgradeableCards, SeasonManager.playerTeam.kicker)
    end
    if SeasonManager.playerTeam.punter and SeasonManager.playerTeam.punter:canUpgrade() then
        table.insert(upgradeableCards, SeasonManager.playerTeam.punter)
    end

    -- Define all possible upgrade types (equal weight)
    local allUpgradeTypes = {
        UPGRADE_TYPE.YARDS,
        UPGRADE_TYPE.COOLDOWN,
        UPGRADE_TYPE.BOOST,
        UPGRADE_TYPE.DURATION,
        UPGRADE_TYPE.BONUS_YARDS,
        UPGRADE_TYPE.IMMUNITY,
        UPGRADE_TYPE.KICKER_RANGE,
        UPGRADE_TYPE.KICKER_ACCURACY,
        UPGRADE_TYPE.PUNTER_RANGE
    }

    -- Generate 3 random options (keep trying until we get 3)
    local attempts = 0
    local maxAttempts = 100  -- Safety limit
    local usedCombinations = {}  -- Track (card, upgrade_type) pairs to avoid exact duplicates

    while #options < 3 and attempts < maxAttempts and #upgradeableCards > 0 do
        attempts = attempts + 1
        local selectedType = allUpgradeTypes[math.random(1, #allUpgradeTypes)]

        -- Card-based upgrades
        local cardIndex = math.random(1, #upgradeableCards)
        local card = upgradeableCards[cardIndex]

        -- Validate upgrade type is compatible with card
        local finalType, finalCost = TrainingScreen.getValidUpgradeForCard(card, selectedType)

        if finalType then
            -- Create a unique key for this (card, upgrade_type) combination
            local combinationKey = tostring(card) .. "_" .. finalType

            -- Check if we've already used this exact combination
            if not usedCombinations[combinationKey] then
                table.insert(options, {
                    type = finalType,
                    card = card,
                    cost = finalCost
                })

                -- Mark this combination as used
                usedCombinations[combinationKey] = true
            end
        end
    end

    TrainingScreen.upgradeOptions = options
end

--- Gets a valid upgrade type for a specific card
--- @param card table The card to upgrade
--- @param preferredType string The preferred upgrade type
--- @return string|nil, number|nil Upgrade type and cost, or nil if invalid
function TrainingScreen.getValidUpgradeForCard(card, preferredType)
    -- Yards upgrade: only for yard generators
    if preferredType == UPGRADE_TYPE.YARDS then
        if card.cardType == Card.TYPE.YARD_GENERATOR and card:canUpgrade() then
            return UPGRADE_TYPE.YARDS, Card.getYardsUpgradeCost()
        end
    end

    -- Boost upgrade: only for boosters
    if preferredType == UPGRADE_TYPE.BOOST then
        if card.cardType == Card.TYPE.BOOSTER and card:canUpgrade() then
            return UPGRADE_TYPE.BOOST, Card.getBoostUpgradeCost()
        end
    end

    -- Duration upgrade: only for defenders
    if preferredType == UPGRADE_TYPE.DURATION then
        if card.cardType == Card.TYPE.DEFENDER and card:canUpgrade() then
            return UPGRADE_TYPE.DURATION, Card.getDurationUpgradeCost()
        end
    end

    -- Bonus yards: only for defenders with REMOVE_YARDS effect
    if preferredType == UPGRADE_TYPE.BONUS_YARDS then
        if card.cardType == Card.TYPE.DEFENDER and card.effectType == Card.EFFECT.REMOVE_YARDS and card:canUpgrade() then
            return UPGRADE_TYPE.BONUS_YARDS, Card.getBonusYardsUpgradeCost()
        end
    end

    -- Immunity: for any card type, but costs 2 slots
    if preferredType == UPGRADE_TYPE.IMMUNITY then
        if not card.hasImmunity and card.upgradeCount <= 1 then
            return UPGRADE_TYPE.IMMUNITY, Card.getImmunityUpgradeCost()
        end
    end

    -- Kicker Range: only for kickers
    if preferredType == UPGRADE_TYPE.KICKER_RANGE then
        if card.cardType == Card.TYPE.KICKER and card:canUpgrade() then
            return UPGRADE_TYPE.KICKER_RANGE, 100
        end
    end

    -- Kicker Accuracy: only for kickers
    if preferredType == UPGRADE_TYPE.KICKER_ACCURACY then
        if card.cardType == Card.TYPE.KICKER and card:canUpgrade() then
            return UPGRADE_TYPE.KICKER_ACCURACY, 150
        end
    end

    -- Punter Range: only for punters
    if preferredType == UPGRADE_TYPE.PUNTER_RANGE then
        if card.cardType == Card.TYPE.PUNTER and card:canUpgrade() then
            return UPGRADE_TYPE.PUNTER_RANGE, 100
        end
    end

    -- Cooldown: universal fallback (not applicable to special teams)
    if card:canUpgrade() and card.cardType ~= Card.TYPE.KICKER and card.cardType ~= Card.TYPE.PUNTER then
        return UPGRADE_TYPE.COOLDOWN, Card.getCooldownUpgradeCost()
    end

    return nil, nil
end

--- LÖVE Callback: Update Logic
--- @param dt number Delta time in seconds
function TrainingScreen.update(dt)
    -- Nothing to update currently
end

--- LÖVE Callback: Draw UI
function TrainingScreen.draw()
    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    local titleText = "Training Week - Choose Upgrades"
    local titleWidth = titleFont:getWidth(titleText)
    love.graphics.print(titleText, (UIScale.getWidth() - titleWidth) / 2, UIScale.scaleY(20))

    -- Draw upgrade options
    local scaledOptionWidth = UIScale.scaleWidth(OPTION_WIDTH)
    local scaledOptionSpacing = UIScale.scaleUniform(OPTION_SPACING)
    local totalWidth = (#TrainingScreen.upgradeOptions * scaledOptionWidth) + ((#TrainingScreen.upgradeOptions - 1) * scaledOptionSpacing)
    local startX = (UIScale.getWidth() - totalWidth) / 2

    local mx, my = love.mouse.getPosition()
    my = my - UIScale.scaleY(100)  -- Adjust for header

    local scaledStartY = UIScale.scaleY(START_Y)
    for i, option in ipairs(TrainingScreen.upgradeOptions) do
        local optionX = startX + ((i - 1) * (scaledOptionWidth + scaledOptionSpacing))

        TrainingScreen.drawUpgradeOption(option, optionX, scaledStartY, mx, my)
    end

    -- Instructions
    love.graphics.setFont(instructFont)
    love.graphics.setColor(0.7, 0.7, 0.8)
    local instructText = "Click on an upgrade to purchase it. You can buy multiple upgrades if you have enough cash."
    local instructWidth = instructFont:getWidth(instructText)
    love.graphics.print(instructText, (UIScale.getWidth() - instructWidth) / 2, scaledStartY + UIScale.scaleHeight(OPTION_HEIGHT) + UIScale.scaleHeight(50))
end

--- Draws a single upgrade option
--- @param option table The upgrade option data
--- @param x number X position
--- @param y number Y position
--- @param mx number Mouse X position
--- @param my number Mouse Y position
function TrainingScreen.drawUpgradeOption(option, x, y, mx, my)
    local scaledOptionWidth = UIScale.scaleWidth(OPTION_WIDTH)
    local scaledOptionHeight = UIScale.scaleHeight(OPTION_HEIGHT)

    local hovering = mx >= x and mx <= x + scaledOptionWidth and
                    my >= y and my <= y + scaledOptionHeight

    local canAfford = SeasonManager.playerTeam and SeasonManager.playerTeam.cash >= option.cost

    -- Background
    if hovering and canAfford then
        love.graphics.setColor(0.25, 0.3, 0.35)
    else
        love.graphics.setColor(0.2, 0.2, 0.25)
    end
    love.graphics.rectangle("fill", x, y, scaledOptionWidth, scaledOptionHeight)

    -- Border
    if canAfford then
        love.graphics.setColor(0.4, 0.5, 0.6)
    else
        love.graphics.setColor(0.3, 0.3, 0.35)
    end
    love.graphics.setLineWidth(UIScale.scaleUniform(3))
    love.graphics.rectangle("line", x, y, scaledOptionWidth, scaledOptionHeight)

    -- Content
    local contentY = y + UIScale.scaleHeight(15)
    local padding = UIScale.scaleUniform(15)

    -- Upgrade type header
    love.graphics.setFont(headerFont)
    love.graphics.setColor(0.8, 0.9, 1)

    local headerText = ""
    if option.type == UPGRADE_TYPE.YARDS then
        headerText = "Upgrade Yards"
    elseif option.type == UPGRADE_TYPE.COOLDOWN then
        headerText = "Upgrade Speed"
    elseif option.type == UPGRADE_TYPE.BOOST then
        headerText = "Upgrade Boost %"
    elseif option.type == UPGRADE_TYPE.DURATION then
        headerText = "Upgrade Duration"
    elseif option.type == UPGRADE_TYPE.BONUS_YARDS then
        headerText = "Bonus Yards Chance"
    elseif option.type == UPGRADE_TYPE.IMMUNITY then
        headerText = "Freeze/Slow Immunity"
    elseif option.type == UPGRADE_TYPE.KICKER_RANGE then
        headerText = "Kicker Range"
    elseif option.type == UPGRADE_TYPE.KICKER_ACCURACY then
        headerText = "Kicker Accuracy"
    elseif option.type == UPGRADE_TYPE.PUNTER_RANGE then
        headerText = "Punter Range"
    elseif option.type == UPGRADE_TYPE.BENCH_CARD then
        headerText = "New Bench Card"
    end

    love.graphics.print(headerText, x + padding, contentY)
    contentY = contentY + UIScale.scaleHeight(35)

    -- Card info
    love.graphics.setFont(cardFont)
    love.graphics.setColor(1, 1, 1)

    local cardText = string.format("#%d %s", option.card.number, option.card.position)
    love.graphics.print(cardText, x + padding, contentY)
    contentY = contentY + UIScale.scaleHeight(30)

    -- Current stats
    love.graphics.setFont(statsFont)
    love.graphics.setColor(0.8, 0.8, 0.9)

    if option.type == UPGRADE_TYPE.YARDS then
        local currentYards = string.format("Current: %.1f yards", option.card.yardsPerAction)
        love.graphics.print(currentYards, x + padding, contentY)
        contentY = contentY + UIScale.scaleHeight(25)

        love.graphics.setColor(0.3, 0.8, 0.3)
        local newYards = string.format("New: %.1f yards (+0.5)", option.card.yardsPerAction + 0.5)
        love.graphics.print(newYards, x + padding, contentY)

    elseif option.type == UPGRADE_TYPE.COOLDOWN then
        local currentCooldown = string.format("Current: %.2fs cooldown", option.card.cooldown)
        love.graphics.print(currentCooldown, x + padding, contentY)
        contentY = contentY + UIScale.scaleHeight(25)

        love.graphics.setColor(0.3, 0.8, 0.3)
        local newCooldown = string.format("New: %.2fs (-10%%)", option.card.cooldown * 0.9)
        love.graphics.print(newCooldown, x + padding, contentY)

    elseif option.type == UPGRADE_TYPE.BOOST then
        local currentBoost = string.format("Current: +%d%% boost", option.card.boostAmount)
        love.graphics.print(currentBoost, x + padding, contentY)
        contentY = contentY + UIScale.scaleHeight(25)

        love.graphics.setColor(0.3, 0.8, 0.3)
        local newBoost = string.format("New: +%d%% boost (+5%%)", option.card.boostAmount + 5)
        love.graphics.print(newBoost, x + padding, contentY)

    elseif option.type == UPGRADE_TYPE.DURATION then
        local currentDuration = string.format("Current: %.1fs duration", option.card.effectStrength)
        love.graphics.print(currentDuration, x + padding, contentY)
        contentY = contentY + UIScale.scaleHeight(25)

        love.graphics.setColor(0.3, 0.8, 0.3)
        local newDuration = string.format("New: %.1fs (+0.5s)", option.card.effectStrength + 0.5)
        love.graphics.print(newDuration, x + padding, contentY)

    elseif option.type == UPGRADE_TYPE.BONUS_YARDS then
        local currentChance = option.card.bonusYardsUpgrades * 33
        local currentText = string.format("Current: %d%% bonus chance", currentChance)
        love.graphics.print(currentText, x + padding, contentY)
        contentY = contentY + UIScale.scaleHeight(25)

        love.graphics.setColor(0.3, 0.8, 0.3)
        local newChance = (option.card.bonusYardsUpgrades + 1) * 33
        local newText = string.format("New: %d%% (+2 yds)", newChance)
        love.graphics.print(newText, x + padding, contentY)

    elseif option.type == UPGRADE_TYPE.IMMUNITY then
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.print("PERMANENT IMMUNITY", x + padding, contentY)
        contentY = contentY + UIScale.scaleHeight(25)

        love.graphics.setColor(0.8, 0.8, 0.9)
        love.graphics.print("Never slowed or frozen", x + padding, contentY)
        contentY = contentY + UIScale.scaleHeight(20)

        love.graphics.setColor(0.8, 0.3, 0.3)
        love.graphics.print("Costs 2 upgrade slots!", x + padding, contentY)

    elseif option.type == UPGRADE_TYPE.KICKER_RANGE then
        local currentRange = string.format("Current: %d yard range", option.card.kickerMaxRange)
        love.graphics.print(currentRange, x + padding, contentY)
        contentY = contentY + UIScale.scaleHeight(25)

        love.graphics.setColor(0.3, 0.8, 0.3)
        local newRange = string.format("New: %d yards (+2)", option.card.kickerMaxRange + 2)
        love.graphics.print(newRange, x + padding, contentY)

    elseif option.type == UPGRADE_TYPE.KICKER_ACCURACY then
        local currentAccuracy = string.format("Current: %d%% max accuracy", option.card.kickerMaxRangeAccuracy)
        love.graphics.print(currentAccuracy, x + padding, contentY)
        contentY = contentY + UIScale.scaleHeight(25)

        love.graphics.setColor(0.3, 0.8, 0.3)
        local newAccuracy = string.format("New: %d%% (+5%%)", option.card.kickerMaxRangeAccuracy + 5)
        love.graphics.print(newAccuracy, x + padding, contentY)

    elseif option.type == UPGRADE_TYPE.PUNTER_RANGE then
        local currentRange = string.format("Current: %d-%d yards", option.card.punterMinRange, option.card.punterMaxRange)
        love.graphics.print(currentRange, x + padding, contentY)
        contentY = contentY + UIScale.scaleHeight(25)

        love.graphics.setColor(0.3, 0.8, 0.3)
        local newRange = string.format("New: %d-%d yards (+5)", option.card.punterMinRange, option.card.punterMaxRange + 5)
        love.graphics.print(newRange, x + padding, contentY)

    elseif option.type == UPGRADE_TYPE.BENCH_CARD then
        local cardInfo = ""
        if option.card.cardType == Card.TYPE.YARD_GENERATOR then
            cardInfo = string.format("%.1f yards / %.2fs", option.card.yardsPerAction, option.card.cooldown)
        elseif option.card.cardType == Card.TYPE.BOOSTER then
            cardInfo = string.format("+%d%% boost / %.2fs", option.card.boostAmount, option.card.cooldown)
        elseif option.card.cardType == Card.TYPE.DEFENDER then
            cardInfo = string.format("%s / %.2fs", option.card.effectType, option.card.cooldown)
        end
        love.graphics.print(cardInfo, x + padding, contentY)
    end

    -- Upgrade count (for existing cards)
    if option.type ~= UPGRADE_TYPE.BENCH_CARD then
        contentY = contentY + UIScale.scaleHeight(30)
        love.graphics.setColor(0.7, 0.7, 0.8)
        local upgradeText = string.format("Upgrades: %d / 3", option.card.upgradeCount)
        love.graphics.print(upgradeText, x + padding, contentY)
    end

    -- Cost
    contentY = y + scaledOptionHeight - UIScale.scaleHeight(50)
    love.graphics.setFont(costFont)

    if canAfford then
        love.graphics.setColor(0.3, 0.8, 0.3)
    else
        love.graphics.setColor(0.8, 0.3, 0.3)
    end

    local costText = string.format("Cost: $%d", option.cost)
    love.graphics.print(costText, x + padding, contentY)

    -- Purchase button
    if canAfford then
        love.graphics.setColor(0.2, 0.6, 0.2)
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
    end

    local btnWidth = UIScale.scaleWidth(120)
    local btnHeight = UIScale.scaleHeight(35)
    local btnX = x + scaledOptionWidth - btnWidth - padding
    local btnY = contentY - UIScale.scaleHeight(5)

    love.graphics.rectangle("fill", btnX, btnY, btnWidth, btnHeight)

    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(UIScale.scaleUniform(2))
    love.graphics.rectangle("line", btnX, btnY, btnWidth, btnHeight)

    love.graphics.setFont(buttonFont)
    if canAfford then
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
    end

    local buyText = "Purchase"
    local buyWidth = buttonFont:getWidth(buyText)
    love.graphics.print(buyText, btnX + (btnWidth - buyWidth) / 2, btnY + UIScale.scaleHeight(5))
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
    local scaledOptionWidth = UIScale.scaleWidth(OPTION_WIDTH)
    local scaledOptionHeight = UIScale.scaleHeight(OPTION_HEIGHT)
    local scaledOptionSpacing = UIScale.scaleUniform(OPTION_SPACING)
    local totalWidth = (#TrainingScreen.upgradeOptions * scaledOptionWidth) + ((#TrainingScreen.upgradeOptions - 1) * scaledOptionSpacing)
    local startX = (UIScale.getWidth() - totalWidth) / 2

    -- Check each option
    local scaledStartY = UIScale.scaleY(START_Y)
    for i, option in ipairs(TrainingScreen.upgradeOptions) do
        local optionX = startX + ((i - 1) * (scaledOptionWidth + scaledOptionSpacing))

        if x >= optionX and x <= optionX + scaledOptionWidth and
           y >= scaledStartY and y <= scaledStartY + scaledOptionHeight then
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
    elseif option.type == UPGRADE_TYPE.BOOST then
        option.card:upgradeBoost()
    elseif option.type == UPGRADE_TYPE.DURATION then
        option.card:upgradeDuration()
    elseif option.type == UPGRADE_TYPE.BONUS_YARDS then
        option.card:upgradeBonusYards()
    elseif option.type == UPGRADE_TYPE.IMMUNITY then
        option.card:upgradeImmunity()
    elseif option.type == UPGRADE_TYPE.KICKER_RANGE then
        option.card:upgradeKickerRange()
    elseif option.type == UPGRADE_TYPE.KICKER_ACCURACY then
        option.card:upgradeKickerAccuracy()
    elseif option.type == UPGRADE_TYPE.PUNTER_RANGE then
        option.card:upgradePunterRange()
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
