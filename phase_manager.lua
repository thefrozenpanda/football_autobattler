-- phase_manager.lua
local CardManager = require("card_manager")
local FieldState = require("field_state")
local Coach = require("coach")
local Card = require("card")

local PhaseManager = {}
PhaseManager.__index = PhaseManager

function PhaseManager:new(playerCoachId, aiCoachId)
    local p = {
        currentPhase = "player_offense",  -- "player_offense" or "player_defense"

        -- Get coach data
        playerCoach = Coach.getById(playerCoachId),
        aiCoach = Coach.getById(aiCoachId),

        -- Scores
        playerScore = 0,
        aiScore = 0
    }
    setmetatable(p, PhaseManager)

    -- Determine starting yards needed (Special Teams gets 68 instead of 80)
    local playerYardsNeeded = (playerCoachId == "special_teams") and 68 or 80
    local aiYardsNeeded = (aiCoachId == "special_teams") and 68 or 80

    -- Create field state
    p.field = FieldState:new(playerYardsNeeded)

    -- Create card managers with coach-specific cards
    p.playerOffense = CardManager:new("player", "offense", p.playerCoach.offensiveCards)
    p.playerDefense = CardManager:new("player", "defense", p.playerCoach.defensiveCards)
    p.aiOffense = CardManager:new("ai", "offense", p.aiCoach.offensiveCards)
    p.aiDefense = CardManager:new("ai", "defense", p.aiCoach.defensiveCards)

    -- Store yards needed for phase switches
    p.playerYardsNeeded = playerYardsNeeded
    p.aiYardsNeeded = aiYardsNeeded

    return p
end

function PhaseManager:update(dt)
    -- Update field state (down timer)
    self.field:update(dt)

    -- Update the appropriate cards based on current phase
    local offense, defense
    if self.currentPhase == "player_offense" then
        offense = self.playerOffense
        defense = self.aiDefense
    else
        offense = self.aiOffense
        defense = self.playerDefense
    end

    -- Update all cards
    for _, card in ipairs(offense.cards) do
        local acted = card:update(dt)
        if acted then
            self:processOffensiveCard(card, offense)
        end
    end

    for _, card in ipairs(defense.cards) do
        local acted = card:update(dt)
        if acted then
            self:processDefensiveCard(card, offense)
        end
    end
end

function PhaseManager:processOffensiveCard(card, offenseManager)
    local action = card:act()
    if not action then return end

    if action.type == "yards" then
        -- Calculate yards with boosts
        local yards = action.value
        local totalBoost = 0

        -- Apply boosts from other offensive cards
        for _, booster in ipairs(offenseManager.cards) do
            if booster.cardType == Card.TYPE.BOOSTER then
                -- Check if this booster targets this card's position
                for _, targetPos in ipairs(booster.boostTargets) do
                    if targetPos == card.position then
                        totalBoost = totalBoost + booster.boostAmount
                        break
                    end
                end
            end
        end

        -- Apply boost
        yards = yards * (1 + totalBoost / 100)

        -- Apply coach ability
        yards = self:applyOffensiveCoachAbility(yards, card)

        -- Add yards to field
        self.field:addYards(yards)

    elseif action.type == "boost" then
        -- Booster cards don't do anything when they act
        -- Their boost is applied when other cards generate yards
    end
end

function PhaseManager:processDefensiveCard(card, offenseManager)
    local action = card:act()
    if not action then return end

    if action.effect == Card.EFFECT.SLOW then
        -- Find target offensive cards
        local targets = offenseManager:getCardsByPosition(action.targets)
        for _, target in ipairs(targets) do
            target:applySlow(action.strength)
        end

    elseif action.effect == Card.EFFECT.FREEZE then
        -- Find target offensive cards
        local targets = offenseManager:getCardsByPosition(action.targets)
        for _, target in ipairs(targets) do
            target:applyFreeze(action.strength)
        end

    elseif action.effect == Card.EFFECT.REMOVE_YARDS then
        -- Remove yards from field
        local yardsToRemove = action.strength

        -- Apply coach ability (Defensive Mastermind)
        if self:isDefensiveMastermind() then
            -- 5% chance to remove 2 extra yards
            if love.math.random() < 0.05 then
                yardsToRemove = yardsToRemove + 2
            end
        end

        self.field:removeYards(yardsToRemove)
    end
end

function PhaseManager:applyOffensiveCoachAbility(yards, card)
    local coach = (self.currentPhase == "player_offense") and self.playerCoach or self.aiCoach

    if coach.id == "offensive_guru" then
        -- +10% yards for all yard generators
        return yards * 1.10

    elseif coach.id == "ground_game" then
        -- RBs gain +2 extra yards per action
        if card.position == "RB" then
            return yards + 2
        end
    end

    return yards
end

function PhaseManager:isDefensiveMastermind()
    if self.currentPhase == "player_offense" then
        return self.aiCoach.id == "defensive_mastermind"
    else
        return self.playerCoach.id == "defensive_mastermind"
    end
end

function PhaseManager:checkPhaseEnd()
    if self.field:hasTouchdown() then
        -- Touchdown scored
        if self.currentPhase == "player_offense" then
            self.playerScore = self.playerScore + 7
        else
            self.aiScore = self.aiScore + 7
        end
        self:switchPhase(true)  -- true = touchdown
        return true

    elseif self.field:isTurnover() then
        -- Turnover on downs
        self:switchPhase(false)  -- false = turnover
        return true
    end

    return false
end

function PhaseManager:switchPhase(isTouchdown)
    local currentFieldPos = self.field:getFieldPosition()

    -- Switch phase
    if self.currentPhase == "player_offense" then
        self.currentPhase = "player_defense"
    else
        self.currentPhase = "player_offense"
    end

    -- Determine new starting position and yards needed
    local yardsNeeded
    if isTouchdown then
        -- After touchdown, offense starts at own 20 (needs 80 yards)
        local coach = (self.currentPhase == "player_offense") and self.playerCoach or self.aiCoach
        yardsNeeded = (coach.id == "special_teams") and 68 or 80
        self.field:reset(nil, yardsNeeded)
    else
        -- After turnover, new offense starts where old offense was
        -- Calculate yards needed from field position
        local yardsFromEndzone = 100 - currentFieldPos
        self.field:reset(currentFieldPos, yardsFromEndzone)
    end
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
