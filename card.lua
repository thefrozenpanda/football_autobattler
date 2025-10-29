-- card.lua
local Card = {}
Card.__index = Card

-- Debug logger (set by match.lua)
Card.logger = nil

-- Card types
Card.TYPE = {
    YARD_GENERATOR = "yard_generator",  -- QB, RB, WR (generates yards)
    BOOSTER = "booster",                -- OL, some TEs (boosts other cards)
    DEFENDER = "defender"                -- All defensive positions
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

        -- Yard generator stats
        yardsPerAction = stats.yardsPerAction or 0,

        -- Booster stats
        boostAmount = stats.boostAmount or 0,       -- Percentage boost (e.g., 20 = 20%)
        boostTargets = stats.boostTargets or {},    -- Which positions to boost (e.g., {"QB", "RB"})

        -- Defensive stats
        effectType = stats.effectType or nil,       -- SLOW, FREEZE, or REMOVE_YARDS
        effectStrength = stats.effectStrength or 0, -- Strength of effect
        targetPositions = stats.targetPositions or {}, -- Which positions to target

        -- Common stats
        speed = stats.speed or 1.5,
        cooldown = stats.speed or 1.5,  -- Cooldown in seconds between actions
        timer = 0,

        -- Visual/state
        justActed = false,
        actHighlightTimer = 0,

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
    -- Returns the result of this card's action
    if self.cardType == Card.TYPE.YARD_GENERATOR then
        return {type = "yards", value = self.yardsPerAction}
    elseif self.cardType == Card.TYPE.BOOSTER then
        return {type = "boost", amount = self.boostAmount, targets = self.boostTargets}
    elseif self.cardType == Card.TYPE.DEFENDER then
        return {type = "defend", effect = self.effectType, strength = self.effectStrength, targets = self.targetPositions}
    end
    return nil
end

function Card:applySlow(duration)
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

return Card
