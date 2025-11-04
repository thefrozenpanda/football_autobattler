-- phase_manager.lua
local CardManager = require("card_manager")
local FieldState = require("field_state")
local Coach = require("coach")
local Card = require("card")

local PhaseManager = {}
PhaseManager.__index = PhaseManager

-- Debug logger (set by match.lua)
PhaseManager.logger = nil

function PhaseManager:new(playerCoachId, aiCoachId, playerKicker, playerPunter, aiKicker, aiPunter)
    local p = {
        currentPhase = "player_offense",  -- "player_offense" or "player_defense"

        -- Get coach data
        playerCoach = Coach.getById(playerCoachId),
        aiCoach = Coach.getById(aiCoachId),

        -- Special teams cards
        playerKicker = playerKicker,
        playerPunter = playerPunter,
        aiKicker = aiKicker,
        aiPunter = aiPunter,

        -- Scores
        playerScore = 0,
        aiScore = 0,

        -- Event tracking for popups (nil = no event)
        lastEvent = nil,  -- "touchdown", "turnover", "field_goal_made", "field_goal_missed", "punt"
        lastEventTeam = nil,  -- "player" or "ai"
        lastEventYards = nil,  -- For field goals and punts
        lastEventSuccess = nil,  -- For field goals

        -- Game clock (set externally by match.lua)
        timeLeft = 60  -- Will be updated by match.lua
    }
    setmetatable(p, PhaseManager)

    -- Determine starting yards needed (Special Teams gets 68 instead of 80)
    local playerYardsNeeded = (playerCoachId == "special_teams") and 68 or 80
    local aiYardsNeeded = (aiCoachId == "special_teams") and 68 or 80

    -- Create field state (player starts on offense, driving forward toward 100)
    p.field = FieldState:new(playerYardsNeeded)
    p.field.drivingForward = true  -- Player drives toward 100

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
        local baseYards = action.value
        local totalBoost = 0
        local boosterCards = {}

        -- Apply boosts from other offensive cards
        for _, booster in ipairs(offenseManager.cards) do
            if booster.cardType == Card.TYPE.BOOSTER then
                -- Check if this booster targets this card's position
                for _, targetPos in ipairs(booster.boostTargets) do
                    if targetPos == card.position then
                        totalBoost = totalBoost + booster.boostAmount
                        table.insert(boosterCards, booster)
                        break
                    end
                end
            end
        end

        -- Apply boost
        local boostedYards = baseYards * (1 + totalBoost / 100)

        -- Apply coach ability
        local finalYards = self:applyOffensiveCoachAbility(boostedYards, card)

        -- Track statistics for boosters
        for _, booster in ipairs(boosterCards) do
            booster.cardsBoosted = booster.cardsBoosted + 1
        end

        -- Track yards gained for this card
        card.yardsGained = card.yardsGained + finalYards

        -- Check if this will cause a touchdown
        local willScoreTD = (self.field.totalYards + finalYards) >= self.field.yardsNeeded
        if willScoreTD then
            card.touchdownsScored = card.touchdownsScored + 1
        end

        -- Log yard generation
        if PhaseManager.logger then
            PhaseManager.logger:logYardGeneration(card, baseYards, boostedYards, finalYards)
        end

        -- Add yards to field
        self.field:addYards(finalYards)

    elseif action.type == "boost" then
        -- Booster cards don't do anything when they act
        -- Their boost is applied when other cards generate yards
        if PhaseManager.logger then
            PhaseManager.logger:logCardAction(card, "BOOST")
        end
    end
end

function PhaseManager:processDefensiveCard(card, offenseManager)
    local action = card:act()
    if not action then return end

    if action.effect == Card.EFFECT.SLOW then
        -- Find target offensive cards
        local targets = offenseManager:getCardsByPosition(action.targets)
        for _, target in ipairs(targets) do
            local applied = target:applySlow(action.strength)
            if applied then
                card.timesSlowed = card.timesSlowed + 1
            end
        end

    elseif action.effect == Card.EFFECT.FREEZE then
        -- Find target offensive cards
        local targets = offenseManager:getCardsByPosition(action.targets)
        for _, target in ipairs(targets) do
            local applied = target:applyFreeze(action.strength)
            if applied then
                card.timesFroze = card.timesFroze + 1
            end
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

        -- Track yards reduced
        card.yardsReduced = card.yardsReduced + yardsToRemove

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
            self.lastEvent = "touchdown"
            self.lastEventTeam = "player"
        else
            self.aiScore = self.aiScore + 7
            self.lastEvent = "touchdown"
            self.lastEventTeam = "ai"
        end
        self:switchPhase(true)  -- true = touchdown
        return true

    elseif self.field:isTurnover() then
        -- Check for special teams play before turnover on downs
        local specialTeamsExecuted = self:checkSpecialTeams()
        if specialTeamsExecuted then
            return true
        end

        -- Regular turnover on downs
        if self.currentPhase == "player_offense" then
            self.lastEvent = "turnover"
            self.lastEventTeam = "player"
        else
            self.lastEvent = "turnover"
            self.lastEventTeam = "ai"
        end
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

    -- Log phase change
    if PhaseManager.logger then
        PhaseManager.logger:logPhaseChange(self.currentPhase)
    end

    -- Determine new starting position, yards needed, and direction
    local yardsNeeded
    local startingPosition
    local drivingForward

    if isTouchdown then
        -- After touchdown/field goal, offense starts at own 20 (needs 80 yards)
        local coach = (self.currentPhase == "player_offense") and self.playerCoach or self.aiCoach
        yardsNeeded = (coach.id == "special_teams") and 68 or 80

        -- Set correct starting position and direction based on which team is on offense
        if self.currentPhase == "player_offense" then
            -- Player drives toward 100, starts at their 20
            startingPosition = 20
            drivingForward = true
        else
            -- AI drives toward 0, starts at their 20 (which is position 80)
            startingPosition = 80
            drivingForward = false
        end

        self.field:reset(startingPosition, yardsNeeded, drivingForward)
    else
        -- After turnover, new offense starts where old offense was
        -- Player team drives toward 100, AI team drives toward 0
        -- Calculate yards needed based on which team now has the ball
        if self.currentPhase == "player_offense" then
            -- Player now has the ball, drives toward 100
            yardsNeeded = 100 - currentFieldPos
            drivingForward = true
        else
            -- AI now has the ball, drives toward 0
            yardsNeeded = currentFieldPos
            drivingForward = false
        end
        self.field:reset(currentFieldPos, yardsNeeded, drivingForward)
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

--- Check if team should attempt field goal or punt
--- @return boolean True if special teams play executed
function PhaseManager:checkSpecialTeams()
    -- Get current team's kicker and punter
    local kicker, punter
    local isPlayerOffense = (self.currentPhase == "player_offense")

    if isPlayerOffense then
        kicker = self.playerKicker
        punter = self.playerPunter
    else
        kicker = self.aiKicker
        punter = self.aiPunter
    end

    if not kicker or not punter then
        return false  -- No special teams available
    end

    -- Calculate yards to endzone (distance for field goal)
    local yardsToEndzone = self.field:getYardsToTouchdown()
    local inFGRange = self:isInFieldGoalRange(yardsToEndzone, kicker)

    -- Get current score differential
    local scoreDiff
    if isPlayerOffense then
        scoreDiff = self.playerScore - self.aiScore  -- positive = winning, negative = losing
    else
        scoreDiff = self.aiScore - self.playerScore
    end

    -- Field goal conditions:
    -- 1. On 4th down in FG range
    -- 2. Trailing by ≤3 with <7s and in range
    local shouldKickFG = false

    if inFGRange then
        shouldKickFG = true  -- Default: always attempt if in range on 4th down
    end

    if scoreDiff <= -1 and scoreDiff >= -3 and self.timeLeft < 7 and inFGRange then
        shouldKickFG = true  -- Desperation field goal
    end

    if shouldKickFG then
        self:attemptFieldGoal(kicker, yardsToEndzone, isPlayerOffense)
        return true
    end

    -- Punt conditions:
    -- 1. 4th down AND out of FG range AND
    -- 2. (score tied/winning OR losing by 4+ with >15s)
    local shouldPunt = false

    if not inFGRange then
        if scoreDiff >= 0 then
            -- Tied or winning: always punt
            shouldPunt = true
        elseif scoreDiff <= -4 and self.timeLeft > 15 then
            -- Losing by 4+, but enough time left: punt
            shouldPunt = true
        end
    end

    if shouldPunt then
        self:executePunt(punter, isPlayerOffense)
        return true
    end

    -- No special teams play: go for it (will result in turnover on downs)
    return false
end

--- Check if distance is within field goal range
--- @param yardsToEndzone number Distance to endzone
--- @param kicker table Kicker card
--- @return boolean True if in range
function PhaseManager:isInFieldGoalRange(yardsToEndzone, kicker)
    if not kicker then return false end

    -- Field goal distance = yards to endzone + 7 (for conversion from line of scrimmage)
    local fgDistance = yardsToEndzone + 7

    return fgDistance <= kicker.kickerMaxRange
end

--- Attempt a field goal
--- @param kicker table Kicker card
--- @param yardsToEndzone number Distance to endzone
--- @param isPlayerOffense boolean True if player is kicking
function PhaseManager:attemptFieldGoal(kicker, yardsToEndzone, isPlayerOffense)
    -- Calculate field goal distance (line of scrimmage + 7 yards)
    local fgDistance = yardsToEndzone + 7

    -- Calculate accuracy: Linear from 100% at 1 yard to maxRangeAccuracy at maxRange
    local maxRange = kicker.kickerMaxRange
    local maxAccuracy = kicker.kickerMaxRangeAccuracy / 100  -- Convert to 0-1

    local accuracy
    if fgDistance <= 1 then
        accuracy = 1.0  -- 100% at 1 yard
    elseif fgDistance >= maxRange then
        accuracy = maxAccuracy
    else
        -- Linear interpolation
        accuracy = 1.0 - ((fgDistance - 1) / (maxRange - 1)) * (1.0 - maxAccuracy)
    end

    -- Random roll
    local roll = love.math.random()
    local made = roll <= accuracy

    if made then
        -- Field goal made: award 3 points
        if isPlayerOffense then
            self.playerScore = self.playerScore + 3
            self.lastEventTeam = "player"
        else
            self.aiScore = self.aiScore + 3
            self.lastEventTeam = "ai"
        end

        self.lastEvent = "field_goal_made"
        self.lastEventYards = fgDistance
        self.lastEventSuccess = true

        -- Log field goal
        if PhaseManager.logger then
            PhaseManager.logger:log(string.format("FIELD GOAL MADE: %d yards (%.0f%% accuracy)", fgDistance, accuracy * 100))
        end

        -- Change possession (like touchdown)
        self:switchPhase(true)
    else
        -- Field goal missed: turnover at line of scrimmage
        self.lastEvent = "field_goal_missed"
        self.lastEventYards = fgDistance
        self.lastEventSuccess = false

        if isPlayerOffense then
            self.lastEventTeam = "player"
        else
            self.lastEventTeam = "ai"
        end

        -- Log field goal
        if PhaseManager.logger then
            PhaseManager.logger:log(string.format("FIELD GOAL MISSED: %d yards (%.0f%% accuracy)", fgDistance, accuracy * 100))
        end

        -- Change possession (like turnover)
        self:switchPhase(false)
    end
end

--- Execute a punt
--- @param punter table Punter card
--- @param isPlayerOffense boolean True if player is punting
function PhaseManager:executePunt(punter, isPlayerOffense)
    -- Random distance between minRange and maxRange
    local actualPuntDistance = love.math.random(punter.punterMinRange, punter.punterMaxRange)
    local netPuntDistance = actualPuntDistance  -- May be adjusted for touchbacks

    -- Calculate new field position
    local currentFieldPos = self.field:getFieldPosition()
    local newFieldPos

    if isPlayerOffense then
        -- Player punts: ball moves toward AI endzone (position 100, on RIGHT)
        newFieldPos = currentFieldPos + actualPuntDistance
        -- Touchback: clamp to opponent's 20-yard line (position 80)
        if newFieldPos > 80 then
            newFieldPos = 80
            netPuntDistance = newFieldPos - currentFieldPos  -- Show net yards
        end
    else
        -- AI punts: ball moves toward player endzone (position 0, on LEFT)
        newFieldPos = currentFieldPos - actualPuntDistance
        -- Touchback: clamp to opponent's 20-yard line (position 20)
        if newFieldPos < 20 then
            newFieldPos = 20
            netPuntDistance = currentFieldPos - newFieldPos  -- Show net yards
        end
    end

    -- Set event data (show actual distance in popup)
    self.lastEvent = "punt"
    self.lastEventYards = actualPuntDistance
    self.lastEventTeam = isPlayerOffense and "player" or "ai"

    -- Log punt
    if PhaseManager.logger then
        if netPuntDistance < actualPuntDistance then
            PhaseManager.logger:log(string.format("PUNT: %d yards (TOUCHBACK, net %d yards, new position: %d)", actualPuntDistance, netPuntDistance, newFieldPos))
        else
            PhaseManager.logger:log(string.format("PUNT: %d yards (new position: %d)", actualPuntDistance, newFieldPos))
        end
    end

    -- Change possession (like turnover, but with specific field position)
    self:switchPhase(false)
end

return PhaseManager
