-- phase_manager.lua
local CardManager = require("card_manager")
local FieldState = require("field_state")
local Coach = require("coach")

local PhaseManager = {}
PhaseManager.__index = PhaseManager

function PhaseManager:new(playerCoachId, aiCoachId)
    local p = {
        currentPhase = "player_offense",  -- "player_offense" or "player_defense"

        -- Get coach data
        playerCoach = Coach.getById(playerCoachId),
        aiCoach = Coach.getById(aiCoachId),

        -- Field state
        field = FieldState:new(),

        -- Scores
        playerScore = 0,
        aiScore = 0,

        -- Coach ability timers
        abilityTimer = 0
    }
    setmetatable(p, PhaseManager)

    -- Create card managers with coach-specific cards
    p.playerOffense = CardManager:new("player", "offense", p.playerCoach.offensiveCards)
    p.playerDefense = CardManager:new("player", "defense", p.playerCoach.defensiveCards)
    p.aiOffense = CardManager:new("ai", "offense", p.aiCoach.offensiveCards)
    p.aiDefense = CardManager:new("ai", "defense", p.aiCoach.defensiveCards)

    return p
end

function PhaseManager:update(dt)
    -- Update ability timer
    self.abilityTimer = self.abilityTimer + dt

    -- Apply coach abilities
    self:applyCoachAbilities(dt)

    -- Update the appropriate cards based on current phase
    if self.currentPhase == "player_offense" then
        self.playerOffense:update(dt)
        self.aiDefense:update(dt)

        -- Calculate yard delta (offense - defense)
        local yardDelta = self:calculateYards(self.playerOffense, self.aiDefense, dt)
        self.field:update(yardDelta, dt)
    else -- player_defense
        self.aiOffense:update(dt)
        self.playerDefense:update(dt)

        -- Calculate yard delta (offense - defense)
        local yardDelta = self:calculateYards(self.aiOffense, self.playerDefense, dt)
        self.field:update(yardDelta, dt)
    end
end

function PhaseManager:applyCoachAbilities(dt)
    -- Apply player coach ability
    if self.currentPhase == "player_offense" then
        self:applyOffensiveAbility(self.playerCoach, self.playerOffense, dt)
    else
        self:applyDefensiveAbility(self.playerCoach, self.playerDefense, dt)
    end

    -- Apply AI coach ability
    if self.currentPhase == "player_offense" then
        self:applyDefensiveAbility(self.aiCoach, self.aiDefense, dt)
    else
        self:applyOffensiveAbility(self.aiCoach, self.aiOffense, dt)
    end
end

function PhaseManager:applyOffensiveAbility(coach, cardManager, dt)
    if coach.id == "offensive_guru" then
        -- No Huddle: Reduce cooldowns by 15%
        for _, card in ipairs(cardManager.cards) do
            card.timer = card.timer + (dt * 0.15)
        end
    elseif coach.id == "ground_game" then
        -- Pound the Rock: Running plays gain power over time (1% per second)
        for _, card in ipairs(cardManager.cards) do
            if card.position == "RB" or card.position == "FB" then
                card.power = card.power + (card.power * 0.01 * dt)
            end
        end
    elseif coach.id == "special_teams" then
        -- Hidden Yardage: Bonus momentum every 6 seconds
        if self.abilityTimer >= 6 then
            self.field.yards = self.field.yards + 2
            self.abilityTimer = 0
        end
    end
end

function PhaseManager:applyDefensiveAbility(coach, cardManager, dt)
    if coach.id == "defensive_mastermind" then
        -- Blitz Package: Defensive surge every 8 seconds
        if self.abilityTimer >= 8 then
            for _, card in ipairs(cardManager.cards) do
                card.power = card.power * 1.5  -- Temporary 50% boost
            end
            self.abilityTimer = 0

            -- Reset power after a short duration (handled in next frame)
            love.timer.sleep(0.1)
            for _, card in ipairs(cardManager.cards) do
                card.power = card.power / 1.5
            end
        end
    end
end

function PhaseManager:calculateYards(offense, defense, dt)
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
    self.abilityTimer = 0  -- Reset ability timer on phase change
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

function PhaseManager:getPlayerCoachName()
    return self.playerCoach.name
end

function PhaseManager:getAICoachName()
    return self.aiCoach.name
end

return PhaseManager
