--- ai_training.lua
--- AI Training and Upgrade Decision Making
---
--- Manages AI team training decisions based on coach difficulty ratings.
--- Elite coaches make strategic upgrades, average coaches are semi-random, weak coaches are random.
---
--- Dependencies: coach.lua, card.lua
--- Used by: season_manager.lua
--- LÖVE Callbacks: None

local Card = require("card")
local Coach = require("coach")

local AITraining = {}

-- Upgrade type constants (matching training_screen.lua)
local UPGRADE_TYPE = {
    YARDS = "yards",
    COOLDOWN = "cooldown",
    BOOST = "boost",
    DURATION = "duration",
    BONUS_YARDS = "bonus_yards",
    IMMUNITY = "immunity",
    KICKER_RANGE = "kicker_range",
    KICKER_ACCURACY = "kicker_accuracy",
    PUNTER_RANGE = "punter_range"
}

--- Generate upgrade options for an AI team
--- @param team table The AI team
--- @return table Array of upgrade options {type, card, cost}
function AITraining.generateUpgradeOptions(team)
    local options = {}

    -- Get all upgradeable cards (offensive + defensive + special teams)
    local upgradeableCards = {}
    for _, card in ipairs(team.offensiveCards) do
        if card:canUpgrade() or (not card.hasImmunity and card.upgradeCount <= 1) then
            table.insert(upgradeableCards, card)
        end
    end
    for _, card in ipairs(team.defensiveCards) do
        if card:canUpgrade() or (not card.hasImmunity and card.upgradeCount <= 1) then
            table.insert(upgradeableCards, card)
        end
    end
    -- Add special teams cards
    if team.kicker and team.kicker:canUpgrade() then
        table.insert(upgradeableCards, team.kicker)
    end
    if team.punter and team.punter:canUpgrade() then
        table.insert(upgradeableCards, team.punter)
    end

    -- Define all possible upgrade types
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

    -- Generate 3 random options
    for i = 1, 3 do
        local selectedType = allUpgradeTypes[math.random(1, #allUpgradeTypes)]

        if #upgradeableCards > 0 then
            local cardIndex = math.random(1, #upgradeableCards)
            local card = upgradeableCards[cardIndex]

            local finalType, finalCost = AITraining.getValidUpgradeForCard(card, selectedType)

            if finalType then
                table.insert(options, {
                    type = finalType,
                    card = card,
                    cost = finalCost
                })

                -- Remove card from pool to avoid duplicates
                if not card:canUpgrade() and finalType ~= UPGRADE_TYPE.IMMUNITY then
                    table.remove(upgradeableCards, cardIndex)
                end
            end
        end
    end

    return options
end

--- Gets a valid upgrade type for a specific card
--- @param card table The card to upgrade
--- @param preferredType string The preferred upgrade type
--- @return string|nil, number|nil Upgrade type and cost, or nil if invalid
function AITraining.getValidUpgradeForCard(card, preferredType)
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

    -- Bonus yards: only for defenders with REMOVE_YARDS
    if preferredType == UPGRADE_TYPE.BONUS_YARDS then
        if card.cardType == Card.TYPE.DEFENDER and card.effectType == Card.EFFECT.REMOVE_YARDS and card:canUpgrade() then
            return UPGRADE_TYPE.BONUS_YARDS, Card.getBonusYardsUpgradeCost()
        end
    end

    -- Cooldown: universal (except special teams)
    if preferredType == UPGRADE_TYPE.COOLDOWN then
        if card:canUpgrade() and card.cardType ~= Card.TYPE.KICKER and card.cardType ~= Card.TYPE.PUNTER then
            return UPGRADE_TYPE.COOLDOWN, Card.getCooldownUpgradeCost()
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

    -- Immunity: special (once per card)
    if preferredType == UPGRADE_TYPE.IMMUNITY then
        if not card.hasImmunity and card.upgradeCount <= 1 then
            return UPGRADE_TYPE.IMMUNITY, Card.getImmunityUpgradeCost()
        end
    end

    -- Fallback: try cooldown if preferred type doesn't work (not for special teams)
    if card:canUpgrade() and card.cardType ~= Card.TYPE.KICKER and card.cardType ~= Card.TYPE.PUNTER then
        return UPGRADE_TYPE.COOLDOWN, Card.getCooldownUpgradeCost()
    end

    return nil, nil
end

--- Calculate strategic value of an upgrade for a coach
--- @param option table Upgrade option {type, card, cost}
--- @param coachData table Coach data from coach.lua
--- @param weekNumber number Current week in season
--- @return number Value score (higher = better)
function AITraining.calculateUpgradeValue(option, coachData, weekNumber)
    local value = 100 -- Base value

    -- Position priority based on coach strategy
    local positionWeight = AITraining.getPositionWeight(option.card.position, coachData)
    value = value * positionWeight

    -- Card type priority
    if option.card.cardType == Card.TYPE.YARD_GENERATOR then
        value = value * 1.3  -- Yard generators are high priority
    elseif option.card.cardType == Card.TYPE.BOOSTER then
        value = value * 1.1  -- Boosters are moderate priority
    elseif option.card.cardType == Card.TYPE.DEFENDER then
        value = value * 1.0  -- Defenders are standard priority
    end

    -- Cost efficiency (cheaper is better early season)
    local costEfficiency = 100 / option.cost
    if weekNumber <= 5 then
        value = value * costEfficiency * 0.5  -- Prioritize cheap upgrades early
    end

    -- Upgrade type value
    if option.type == UPGRADE_TYPE.YARDS or option.type == UPGRADE_TYPE.BONUS_YARDS then
        value = value * 1.3  -- Direct stat upgrades are valuable
    elseif option.type == UPGRADE_TYPE.COOLDOWN then
        value = value * 1.2  -- Speed upgrades are very valuable
    elseif option.type == UPGRADE_TYPE.IMMUNITY then
        value = value * 0.9  -- Immunity is situational
    end

    return value
end

--- Get position weight based on coach strategy
--- @param position string Card position
--- @param coachData table Coach data
--- @return number Weight multiplier (0.5 to 2.0)
function AITraining.getPositionWeight(position, coachData)
    local coachId = coachData.id

    -- Offensive Guru: prioritize QB, WR, TE
    if coachId == "offensive_guru" then
        if position == "QB" then return 2.0 end
        if position == "WR" or position == "TE" then return 1.5 end
        if position == "RB" then return 1.0 end
        if position == "OL" then return 1.2 end
        return 1.0 -- Defensive positions
    end

    -- Defensive Mastermind: prioritize defense
    if coachId == "defensive_mastermind" then
        if position == "DL" or position == "LB" or position == "CB" or position == "S" then
            return 1.8
        end
        return 0.8 -- Offensive positions
    end

    -- Ground Game: prioritize RB, OL
    if coachId == "ground_game" then
        if position == "RB" then return 2.0 end
        if position == "OL" then return 1.8 end
        if position == "QB" then return 0.7 end
        return 1.0
    end

    -- Special Teams: balanced
    return 1.0
end

--- Process AI team upgrades for the week
--- @param team table The AI team
--- @param weekNumber number Current week in season
function AITraining.processWeeklyUpgrades(team, weekNumber)
    if team.isPlayer then
        return  -- Skip player team
    end

    -- Get coach data
    local coachData = Coach.getById(team.coachId)
    if not coachData then
        return
    end

    -- Generate upgrade options
    local options = AITraining.generateUpgradeOptions(team)

    -- Keep purchasing upgrades while cash available
    while #options > 0 and team.cash > 0 do
        local selectedOption = nil

        -- Select based on difficulty
        if coachData.difficulty == "elite" then
            -- Elite: Pick best strategic value
            selectedOption = AITraining.selectBestUpgrade(options, coachData, weekNumber)
        elseif coachData.difficulty == "average" then
            -- Average: 70% strategic, 30% random
            if math.random() < 0.7 then
                selectedOption = AITraining.selectBestUpgrade(options, coachData, weekNumber)
            else
                selectedOption = AITraining.selectRandomAffordable(options, team.cash)
            end
        else -- weak
            -- Weak: Random affordable
            selectedOption = AITraining.selectRandomAffordable(options, team.cash)
        end

        -- Purchase if found and affordable
        if selectedOption and team:spendCash(selectedOption.cost) then
            AITraining.applyUpgrade(selectedOption)
            -- Remove from options
            for i, opt in ipairs(options) do
                if opt == selectedOption then
                    table.remove(options, i)
                    break
                end
            end
        else
            break  -- Can't afford anything, stop
        end
    end
end

--- Select best upgrade based on strategic value
--- @param options table Array of upgrade options
--- @param coachData table Coach data
--- @param weekNumber number Current week
--- @return table|nil Best option or nil
function AITraining.selectBestUpgrade(options, coachData, weekNumber)
    local bestOption = nil
    local bestValue = 0

    for _, option in ipairs(options) do
        local value = AITraining.calculateUpgradeValue(option, coachData, weekNumber)
        if value > bestValue then
            bestValue = value
            bestOption = option
        end
    end

    return bestOption
end

--- Select random affordable upgrade
--- @param options table Array of upgrade options
--- @param availableCash number Team's available cash
--- @return table|nil Random affordable option or nil
function AITraining.selectRandomAffordable(options, availableCash)
    local affordable = {}
    for _, option in ipairs(options) do
        if option.cost <= availableCash then
            table.insert(affordable, option)
        end
    end

    if #affordable > 0 then
        return affordable[math.random(1, #affordable)]
    end

    return nil
end

--- Apply an upgrade to a card
--- @param option table Upgrade option {type, card, cost}
function AITraining.applyUpgrade(option)
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
    end
end

return AITraining
