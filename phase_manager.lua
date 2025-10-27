-- phase_manager.lua
local CardManager = require("card_manager")
local FieldState = require("field_state")

local PhaseManager = {}
PhaseManager.__index = PhaseManager

function PhaseManager:new()
    local p = {
        currentPhase = "player_offense",  -- "player_offense" or "player_defense"

        -- Player cards
        playerOffense = CardManager:new("player", "offense"),
        playerDefense = CardManager:new("player", "defense"),

        -- AI cards
        aiOffense = CardManager:new("ai", "offense"),
        aiDefense = CardManager:new("ai", "defense"),

        -- Field state
        field = FieldState:new(),

        -- Scores
        playerScore = 0,
        aiScore = 0
    }
    setmetatable(p, PhaseManager)
    return p
end

function PhaseManager:update(dt)
    -- Update the appropriate cards based on current phase
    if self.currentPhase == "player_offense" then
        self.playerOffense:update(dt)
        self.aiDefense:update(dt)

        -- Calculate yard delta (offense - defense)
        local yardDelta = self:calculateYards(self.playerOffense, self.aiDefense)
        self.field:update(yardDelta, dt)
    else -- player_defense
        self.aiOffense:update(dt)
        self.playerDefense:update(dt)

        -- Calculate yard delta (offense - defense)
        local yardDelta = self:calculateYards(self.aiOffense, self.playerDefense)
        self.field:update(yardDelta, dt)
    end
end

function PhaseManager:calculateYards(offense, defense)
    local offensePower = 0
    local defensePower = 0

    for _, card in ipairs(offense.cards) do
        -- Card:update already called Card:act when timer reached cooldown
        -- We don't double-act here
    end

    for _, card in ipairs(defense.cards) do
        -- Same as above
    end

    -- Simple calculation: sum of offense powers vs defense powers
    -- Scaled down for reasonable yard gains
    local offenseTotal = offense:getTotalPower()
    local defenseTotal = defense:getTotalPower()

    return (offenseTotal - defenseTotal) * 0.002 * dt
end

function PhaseManager:checkPhaseEnd()
    if self.field:hasTouchdown() then
        -- Touchdown scored
        if self.currentPhase == "player_offense" then
            self.playerScore = self.playerScore + 7
        else
            self.aiScore = self.aiScore + 7
        end
        self:switchPhase()
        return true
    elseif self.field:isTurnover() then
        -- Turnover on downs
        self:switchPhase()
        return true
    end
    return false
end

function PhaseManager:switchPhase()
    if self.currentPhase == "player_offense" then
        self.currentPhase = "player_defense"
    else
        self.currentPhase = "player_offense"
    end
    self.field:reset()
end

function PhaseManager:getActivePlayerCards()
    if self.currentPhase == "player_offense" then
        return self.playerOffense.cards
    else
        return self.playerDefense.cards
    end
end

function PhaseManager:getActiveAICards()
    if self.currentPhase == "player_offense" then
        return self.aiDefense.cards
    else
        return self.aiOffense.cards
    end
end

function PhaseManager:getCurrentPhaseName()
    if self.currentPhase == "player_offense" then
        return "Offense"
    else
        return "Defense"
    end
end

return PhaseManager

