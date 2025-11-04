-- card.lua
local lume = require("lib.lume")

local Card = {}
Card.__index = Card

-- Debug logger (set by match.lua)
Card.logger = nil

-- Card types
Card.TYPE = {
    YARD_GENERATOR = "yard_generator",  -- QB, RB, WR (generates yards)
    BOOSTER = "booster",                -- OL, some TEs (boosts other cards)
    DEFENDER = "defender",              -- All defensive positions
    KICKER = "kicker",                  -- Field goal kicker
    PUNTER = "punter"                   -- Punter
}

-- Defensive effect types
Card.EFFECT = {
    SLOW = "slow",              -- Reduces progress rate to 50%
    FREEZE = "freeze",          -- Stops progress for 1 second
    REMOVE_YARDS = "remove_yards"  -- Removes yards from offense
}

function Card:new(position, cardType, stats)
    local c = {
        position = position or "Unknown",
        cardType = cardType,
        number = stats.number or Card.generateNumber(position),  -- Jersey number

        -- Yard generator stats (with ranges)
        yardsPerActionMin = stats.yardsPerActionMin or stats.yardsPerAction or 0,
        yardsPerActionMax = stats.yardsPerActionMax or stats.yardsPerAction or 0,
        yardsPerAction = stats.yardsPerAction or 0,  -- Kept for compatibility
        baseYardsPerAction = stats.yardsPerAction or 0,  -- Original value before upgrades

        -- Booster stats (with ranges)
        boostAmountMin = stats.boostAmountMin or stats.boostAmount or 0,
        boostAmountMax = stats.boostAmountMax or stats.boostAmount or 0,
        boostAmount = stats.boostAmount or 0,       -- Percentage boost (e.g., 20 = 20%)
        boostTargets = stats.boostTargets or {},    -- Which positions to boost (e.g., {"QB", "RB"})

        -- Defensive stats (with ranges)
        effectType = stats.effectType or nil,       -- SLOW, FREEZE, or REMOVE_YARDS
        effectStrengthMin = stats.effectStrengthMin or stats.effectStrength or 0,
        effectStrengthMax = stats.effectStrengthMax or stats.effectStrength or 0,
        effectStrength = stats.effectStrength or 0, -- Strength of effect
        targetPositions = stats.targetPositions or {}, -- Which positions to target

        -- Kicker stats
        kickerMaxRange = stats.kickerMaxRange or 50,         -- Max FG distance (default 50 yards)
        kickerMaxRangeAccuracy = stats.kickerMaxRangeAccuracy or 70,  -- Accuracy at max range (default 70%)
        baseKickerMaxRange = stats.kickerMaxRange or 50,     -- Original before upgrades
        baseKickerMaxRangeAccuracy = stats.kickerMaxRangeAccuracy or 70,  -- Original before upgrades

        -- Punter stats
        punterMinRange = stats.punterMinRange or 35,         -- Min punt distance (default 35 yards)
        punterMaxRange = stats.punterMaxRange or 50,         -- Max punt distance (default 50 yards)
        basePunterMaxRange = stats.punterMaxRange or 50,     -- Original before upgrades

        -- Common stats
        speed = stats.speed or 1.5,
        cooldown = stats.speed or 1.5,  -- Cooldown in seconds between actions
        baseCooldown = stats.speed or 1.5,  -- Original cooldown before upgrades
        timer = 0,

        -- Upgrade tracking
        upgradeCount = 0,           -- Number of upgrades applied (max 3)
        yardsUpgrades = 0,          -- Number of yards upgrades applied
        cooldownUpgrades = 0,       -- Number of cooldown upgrades applied
        boostUpgrades = 0,          -- Number of booster % upgrades applied
        durationUpgrades = 0,       -- Number of defender duration upgrades applied
        bonusYardsUpgrades = 0,     -- Number of bonus yards upgrades applied
        kickerRangeUpgrades = 0,    -- Number of kicker max range upgrades
        kickerAccuracyUpgrades = 0, -- Number of kicker accuracy upgrades
        punterRangeUpgrades = 0,    -- Number of punter max range upgrades
        hasImmunity = false,        -- Whether card has freeze/slow immunity

        -- Visual/state
        justActed = false,
        actHighlightTimer = 0,
        animOffsetX = 0,  -- Horizontal animation offset

        -- Status effects applied to this card
        isSlowed = false,
        slowTimer = 0,
        isFrozen = false,
        freezeTimer = 0,

        -- Match statistics (tracked throughout the match)
        -- Offensive stats
        yardsGained = 0,           -- Total yards this card generated
        touchdownsScored = 0,      -- TDs credited to this card
        cardsBoosted = 0,          -- Times this booster applied boost to another card's action

        -- Defensive stats
        timesSlowed = 0,           -- Times this card applied slow effect
        timesFroze = 0,            -- Times this card applied freeze effect
        yardsReduced = 0           -- Total yards removed by this card
    }
    setmetatable(c, Card)
    return c
end

function Card:update(dt)
    -- Check for speed anomalies
    if Card.logger and (self.cooldown < 0.1 or self.cooldown > 10) then
        Card.logger:logSpeedAnomaly(self, "Abnormal cooldown detected")
    end

    -- Update status effect timers
    if self.slowTimer > 0 then
        self.slowTimer = self.slowTimer - dt
        if self.slowTimer <= 0 then
            self.isSlowed = false
        end
    end

    if self.freezeTimer > 0 then
        self.freezeTimer = self.freezeTimer - dt
        if self.freezeTimer <= 0 then
            self.isFrozen = false
        end
    end

    -- Update action highlight timer
    if self.actHighlightTimer > 0 then
        self.actHighlightTimer = self.actHighlightTimer - dt
        if self.actHighlightTimer <= 0 then
            self.justActed = false
        end
    end

    -- Don't progress timer if frozen
    if self.isFrozen then
        return false
    end

    -- Progress timer (slower if slowed)
    local progressRate = self.isSlowed and 0.5 or 1.0
    self.timer = self.timer + (dt * progressRate)

    if self.timer >= self.cooldown then
        self.timer = 0
        self.justActed = true
        self.actHighlightTimer = 0.2  -- Highlight for 0.2 seconds

        -- Log card action
        if Card.logger then
            Card.logger:logCardUpdate(self, dt, true)
        end

        return true  -- Card acted
    end
    return false
end

function Card:act()
    -- Returns the result of this card's action with randomized values within ranges
    if self.cardType == Card.TYPE.YARD_GENERATOR then
        -- Generate random yards within min/max range
        local yards = math.random() * (self.yardsPerActionMax - self.yardsPerActionMin) + self.yardsPerActionMin
        return {type = "yards", value = yards}
    elseif self.cardType == Card.TYPE.BOOSTER then
        -- Generate random boost within min/max range
        local boost = math.random() * (self.boostAmountMax - self.boostAmountMin) + self.boostAmountMin
        return {type = "boost", amount = boost, targets = self.boostTargets}
    elseif self.cardType == Card.TYPE.DEFENDER then
        -- Generate random effect strength within min/max range
        local strength = math.random() * (self.effectStrengthMax - self.effectStrengthMin) + self.effectStrengthMin
        return {type = "defend", effect = self.effectType, strength = strength, targets = self.targetPositions}
    end
    return nil
end

function Card:applySlow(duration)
    -- Check immunity first
    if self.hasImmunity then
        return false  -- Immune to slow
    end

    -- Only apply if not already slowed
    if not self.isSlowed then
        self.isSlowed = true
        self.slowTimer = duration or 2.0  -- Default 2 seconds

        if Card.logger then
            Card.logger:logStatusEffect(self, "SLOW", self.slowTimer)
        end
        return true  -- Successfully applied
    end
    return false  -- Already slowed
end

function Card:applyFreeze(duration)
    -- Check immunity first
    if self.hasImmunity then
        return false  -- Immune to freeze
    end

    -- Only apply if not already frozen
    if not self.isFrozen then
        self.isFrozen = true
        self.freezeTimer = duration or 1.0  -- Default 1 second

        if Card.logger then
            Card.logger:logStatusEffect(self, "FREEZE", self.freezeTimer)
        end
        return true  -- Successfully applied
    end
    return false  -- Already frozen
end

function Card:getProgress()
    return self.timer / self.cooldown
end

--- Generates a position-realistic jersey number
--- @param position string Position abbreviation (QB, RB, WR, etc.)
--- @return number Jersey number
function Card.generateNumber(position)
    -- Position-realistic number ranges
    if position == "QB" then
        return math.random(1, 19)
    elseif position == "RB" then
        return math.random(20, 49)
    elseif position == "WR" then
        -- WRs can be 10-19 or 80-89
        return math.random(0, 1) == 0 and math.random(10, 19) or math.random(80, 89)
    elseif position == "TE" then
        -- TEs can be 40-49 or 80-89
        return math.random(0, 1) == 0 and math.random(40, 49) or math.random(80, 89)
    elseif position == "OL" then
        return math.random(50, 79)
    elseif position == "DL" then
        -- DL can be 50-79 or 90-99
        return math.random(0, 1) == 0 and math.random(50, 79) or math.random(90, 99)
    elseif position == "LB" then
        -- LBs can be 40-59 or 90-99
        return math.random(0, 1) == 0 and math.random(40, 59) or math.random(90, 99)
    elseif position == "CB" or position == "S" then
        return math.random(20, 49)
    else
        return math.random(1, 99)
    end
end

--- Checks if this card can be upgraded
--- @return boolean True if card has not reached max upgrades (3)
function Card:canUpgrade()
    return self.upgradeCount < 3
end

--- Upgrades the card's yards per action
--- Cost: 50 cash, Effect: +0.5 yards per action
--- @return boolean True if upgrade successful
function Card:upgradeYards()
    if not self:canUpgrade() then
        return false
    end

    if self.cardType ~= Card.TYPE.YARD_GENERATOR then
        return false  -- Only yard generators can upgrade yards
    end

    self.yardsPerAction = self.yardsPerAction + 0.5
    self.yardsUpgrades = self.yardsUpgrades + 1
    self.upgradeCount = self.upgradeCount + 1

    return true
end

--- Upgrades the card's cooldown (makes card faster)
--- Cost: 75 cash, Effect: -10% cooldown
--- @return boolean True if upgrade successful
function Card:upgradeCooldown()
    if not self:canUpgrade() then
        return false
    end

    -- Reduce cooldown by 10%
    self.cooldown = self.cooldown * 0.9
    self.speed = self.cooldown  -- Keep speed in sync
    self.cooldownUpgrades = self.cooldownUpgrades + 1
    self.upgradeCount = self.upgradeCount + 1

    return true
end

--- Gets the cost of upgrading yards
--- @return number Cost in cash
function Card.getYardsUpgradeCost()
    return 50
end

--- Gets the cost of upgrading cooldown
--- @return number Cost in cash
function Card.getCooldownUpgradeCost()
    return 75
end

--- Gets the cost of a new bench card
--- @return number Cost in cash
function Card.getBenchCardCost()
    return 200
end

--- Upgrades the booster percentage (boosters only)
--- Cost: 125 cash, Effect: +5% boost (20% → 25%)
--- @return boolean True if upgrade successful
function Card:upgradeBoost()
    if not self:canUpgrade() then
        return false
    end

    if self.cardType ~= Card.TYPE.BOOSTER then
        return false  -- Only boosters can upgrade boost %
    end

    self.boostAmount = self.boostAmount + 5
    self.boostUpgrades = self.boostUpgrades + 1
    self.upgradeCount = self.upgradeCount + 1

    return true
end

--- Upgrades the defender effect duration (defenders only)
--- Cost: 150 cash, Effect: +0.5s duration (2.0s → 2.5s)
--- @return boolean True if upgrade successful
function Card:upgradeDuration()
    if not self:canUpgrade() then
        return false
    end

    if self.cardType ~= Card.TYPE.DEFENDER then
        return false  -- Only defenders can upgrade duration
    end

    self.effectStrength = self.effectStrength + 0.5
    self.durationUpgrades = self.durationUpgrades + 1
    self.upgradeCount = self.upgradeCount + 1

    return true
end

--- Upgrades card to have 33% chance for +2 bonus yards (yard generators only)
--- Cost: 200 cash, Effect: 33% chance to gain +2 yards per action
--- @return boolean True if upgrade successful
function Card:upgradeBonusYards()
    if not self:canUpgrade() then
        return false
    end

    if self.cardType ~= Card.TYPE.YARD_GENERATOR then
        return false  -- Only yard generators can get bonus yards
    end

    self.bonusYardsUpgrades = self.bonusYardsUpgrades + 1
    self.upgradeCount = self.upgradeCount + 1

    return true
end

--- Upgrades card to have permanent freeze/slow immunity
--- Cost: 400 cash, Effect: Never affected by freeze or slow
--- IMPORTANT: Counts as 2 upgrade slots!
--- @return boolean True if upgrade successful
function Card:upgradeImmunity()
    -- Immunity costs 2 slots, so need at least 2 slots remaining
    if self.upgradeCount > 1 then
        return false
    end

    self.hasImmunity = true
    self.upgradeCount = self.upgradeCount + 2  -- Takes 2 slots!

    return true
end

--- Gets the cost of upgrading booster percentage
--- @return number Cost in cash
function Card.getBoostUpgradeCost()
    return 125
end

--- Gets the cost of upgrading defender duration
--- @return number Cost in cash
function Card.getDurationUpgradeCost()
    return 150
end

--- Gets the cost of upgrading bonus yards chance
--- @return number Cost in cash
function Card.getBonusYardsUpgradeCost()
    return 200
end

--- Gets the cost of immunity upgrade
--- @return number Cost in cash
function Card.getImmunityUpgradeCost()
    return 400
end

--- Gets the cost of upgrading kicker max range
--- @return number Cost in cash
function Card.getKickerRangeUpgradeCost()
    return 100
end

--- Gets the cost of upgrading kicker accuracy
--- @return number Cost in cash
function Card.getKickerAccuracyUpgradeCost()
    return 150
end

--- Gets the cost of upgrading punter max range
--- @return number Cost in cash
function Card.getPunterRangeUpgradeCost()
    return 100
end

--- Upgrades the kicker's max range
--- Cost: 100 cash, Effect: +2 yards max range
--- @return boolean True if upgrade successful
function Card:upgradeKickerRange()
    if not self:canUpgrade() then
        return false
    end

    if self.cardType ~= Card.TYPE.KICKER then
        return false
    end

    self.kickerMaxRange = self.kickerMaxRange + 2
    self.kickerRangeUpgrades = self.kickerRangeUpgrades + 1
    self.upgradeCount = self.upgradeCount + 1
    return true
end

--- Upgrades the kicker's max range accuracy
--- Cost: 150 cash, Effect: +5% accuracy at max range
--- @return boolean True if upgrade successful
function Card:upgradeKickerAccuracy()
    if not self:canUpgrade() then
        return false
    end

    if self.cardType ~= Card.TYPE.KICKER then
        return false
    end

    self.kickerMaxRangeAccuracy = self.kickerMaxRangeAccuracy + 5
    self.kickerAccuracyUpgrades = self.kickerAccuracyUpgrades + 1
    self.upgradeCount = self.upgradeCount + 1
    return true
end

--- Upgrades the punter's max range
--- Cost: 100 cash, Effect: +5 yards max range
--- @return boolean True if upgrade successful
function Card:upgradePunterRange()
    if not self:canUpgrade() then
        return false
    end

    if self.cardType ~= Card.TYPE.PUNTER then
        return false
    end

    self.punterMaxRange = self.punterMaxRange + 5
    self.punterRangeUpgrades = self.punterRangeUpgrades + 1
    self.upgradeCount = self.upgradeCount + 1
    return true
end

--- Calculates actual yards considering bonus yards chance
--- @param baseYards number Base yards from card
--- @return number Final yards (with potential bonus)
function Card:calculateYardsWithBonus(baseYards)
    if self.bonusYardsUpgrades > 0 then
        -- Each bonus yards upgrade gives 33% chance for +2 yards
        local totalChance = self.bonusYardsUpgrades * 0.33
        totalChance = math.min(totalChance, 0.99)  -- Cap at 99%

        if math.random() < totalChance then
            return baseYards + 2
        end
    end

    return baseYards
end

--- Resets upgrade tracking (for new season)
function Card:resetUpgrades()
    self.yardsPerAction = self.baseYardsPerAction
    self.cooldown = self.baseCooldown
    self.speed = self.baseCooldown
    self.kickerMaxRange = self.baseKickerMaxRange
    self.kickerMaxRangeAccuracy = self.baseKickerMaxRangeAccuracy
    self.punterMaxRange = self.basePunterMaxRange
    self.upgradeCount = 0
    self.yardsUpgrades = 0
    self.cooldownUpgrades = 0
    self.boostUpgrades = 0
    self.durationUpgrades = 0
    self.bonusYardsUpgrades = 0
    self.kickerRangeUpgrades = 0
    self.kickerAccuracyUpgrades = 0
    self.punterRangeUpgrades = 0
    self.hasImmunity = false
end

--- Recalculates stats based on stored upgrade counts (used when loading from save)
function Card:recalculateStats()
    -- Start from base stats
    self.yardsPerAction = self.baseYardsPerAction
    self.cooldown = self.baseCooldown
    self.speed = self.baseCooldown

    -- Apply yards upgrades (+0.5 per upgrade)
    if self.yardsUpgrades and self.yardsUpgrades > 0 then
        self.yardsPerAction = self.yardsPerAction + (self.yardsUpgrades * 0.5)
    end

    -- Apply cooldown upgrades (-10% per upgrade)
    if self.cooldownUpgrades and self.cooldownUpgrades > 0 then
        for i = 1, self.cooldownUpgrades do
            self.cooldown = self.cooldown * 0.9
        end
        self.speed = self.cooldown
    end

    -- Apply boost upgrades (+5% per upgrade)
    if self.boostUpgrades and self.boostUpgrades > 0 then
        -- Need to calculate base boost amount
        local baseBoost = self.boostAmount - (self.boostUpgrades * 5)
        self.boostAmount = baseBoost + (self.boostUpgrades * 5)
    end

    -- Apply duration upgrades (+0.5s per upgrade)
    if self.durationUpgrades and self.durationUpgrades > 0 then
        -- Need to calculate base effect strength
        local baseStrength = self.effectStrength - (self.durationUpgrades * 0.5)
        self.effectStrength = baseStrength + (self.durationUpgrades * 0.5)
    end

    -- Apply kicker range upgrades (+2 yards per upgrade)
    if self.kickerRangeUpgrades and self.kickerRangeUpgrades > 0 then
        self.kickerMaxRange = self.baseKickerMaxRange + (self.kickerRangeUpgrades * 2)
    end

    -- Apply kicker accuracy upgrades (+5% per upgrade)
    if self.kickerAccuracyUpgrades and self.kickerAccuracyUpgrades > 0 then
        self.kickerMaxRangeAccuracy = self.baseKickerMaxRangeAccuracy + (self.kickerAccuracyUpgrades * 5)
    end

    -- Apply punter range upgrades (+5 yards per upgrade)
    if self.punterRangeUpgrades and self.punterRangeUpgrades > 0 then
        self.punterMaxRange = self.basePunterMaxRange + (self.punterRangeUpgrades * 5)
    end

    -- bonusYardsUpgrades and hasImmunity are already stored as flags, no recalc needed
end

return Card
