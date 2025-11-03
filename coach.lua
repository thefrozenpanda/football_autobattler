-- coach.lua
-- Defines the 4 head coach archetypes with full 11-man rosters

local Card = require("card")
local Coach = {}

-- Helper function to create yard generator
local function yardGen(pos, yards, spd)
    return {position = pos, cardType = Card.TYPE.YARD_GENERATOR, stats = {yardsPerAction = yards, speed = spd}}
end

-- Helper function to create booster
local function booster(pos, boost, targets, spd)
    return {position = pos, cardType = Card.TYPE.BOOSTER, stats = {boostAmount = boost, boostTargets = targets, speed = spd}}
end

-- Helper function to create defender
local function defender(pos, effect, strength, targets, spd)
    return {position = pos, cardType = Card.TYPE.DEFENDER, stats = {effectType = effect, effectStrength = strength, targetPositions = targets, speed = spd}}
end

-- Coach type definitions
Coach.types = {
    {
        id = "offensive_guru",
        name = "Offensive Guru",
        description = "High-scoring, aggressive passing offense",
        signature = "Air Raid",
        signatureDesc = "+10% yards for all yard generators",
        color = {0.9, 0.3, 0.2}, -- Red
        difficulty = "elite", -- Elite coach with strategic upgrades

        -- Offensive lineup (11 players) - Passing focused
        offensiveCards = {
            yardGen("QB", 4.5, 3.6),    -- Franchise QB
            yardGen("RB", 2.5, 4.4),    -- Receiving back
            yardGen("RB", 2.5, 4.4),
            booster("OL", 25, {"QB"}, 4.0),  -- Center
            booster("OL", 20, {"QB"}, 4.0),  -- Guard
            booster("OL", 20, {"QB"}, 4.0),  -- Guard
            booster("OL", 18, {"QB"}, 4.0),  -- Tackle
            booster("OL", 18, {"QB"}, 4.0),  -- Tackle
            yardGen("WR", 3.5, 5.2),    -- WR1
            yardGen("WR", 3.5, 5.2),    -- WR2
            booster("TE", 15, {"QB"}, 4.2) -- Blocking TE
        },

        -- Defensive lineup (11 players) - Balanced defense
        defensiveCards = {
            defender("DL", Card.EFFECT.SLOW, 2.0, {"QB"}, 3.8),
            defender("DL", Card.EFFECT.REMOVE_YARDS, 1.5, {}, 3.6),
            defender("DL", Card.EFFECT.SLOW, 2.0, {"QB"}, 3.8),
            defender("DL", Card.EFFECT.REMOVE_YARDS, 1.5, {}, 3.6),
            defender("LB", Card.EFFECT.SLOW, 2.0, {"RB", "OL"}, 4.2),
            defender("LB", Card.EFFECT.FREEZE, 1.0, {"RB"}, 4.0),
            defender("LB", Card.EFFECT.SLOW, 2.0, {"OL"}, 4.2),
            defender("CB", Card.EFFECT.FREEZE, 1.0, {"WR"}, 5.0),
            defender("CB", Card.EFFECT.FREEZE, 1.0, {"WR"}, 5.0),
            defender("S", Card.EFFECT.SLOW, 2.0, {"TE", "WR"}, 4.4),
            defender("S", Card.EFFECT.SLOW, 2.0, {"TE", "WR"}, 4.4)
        }
    },

    {
        id = "defensive_mastermind",
        name = "Defensive Mastermind",
        description = "Defense wins championships",
        signature = "Blitz Package",
        signatureDesc = "5% chance to remove 2 yards on defensive action",
        color = {0.2, 0.4, 0.9}, -- Blue
        difficulty = "elite", -- Elite coach with strategic upgrades

        -- Offensive lineup (11 players) - Conservative offense
        offensiveCards = {
            yardGen("QB", 3.5, 3.4),    -- Game manager QB
            yardGen("RB", 3.0, 4.2),
            yardGen("RB", 3.0, 4.2),
            booster("OL", 20, {"QB", "RB"}, 3.8),
            booster("OL", 18, {"QB", "RB"}, 3.8),
            booster("OL", 18, {"QB", "RB"}, 3.8),
            booster("OL", 15, {"RB"}, 3.8),
            booster("OL", 15, {"RB"}, 3.8),
            yardGen("WR", 3.0, 4.8),
            yardGen("WR", 3.0, 4.8),
            yardGen("TE", 2.5, 4.0)     -- Receiving TE
        },

        -- Defensive lineup (11 players) - DOMINANT defense
        defensiveCards = {
            defender("DL", Card.EFFECT.REMOVE_YARDS, 2.0, {}, 3.6),
            defender("DL", Card.EFFECT.SLOW, 2.5, {"QB"}, 3.8),
            defender("DL", Card.EFFECT.REMOVE_YARDS, 2.0, {}, 3.6),
            defender("DL", Card.EFFECT.SLOW, 2.5, {"QB"}, 3.8),
            defender("LB", Card.EFFECT.FREEZE, 1.2, {"RB", "OL"}, 4.0),
            defender("LB", Card.EFFECT.SLOW, 2.5, {"RB"}, 4.2),
            defender("LB", Card.EFFECT.FREEZE, 1.2, {"OL"}, 4.0),
            defender("CB", Card.EFFECT.FREEZE, 1.2, {"WR"}, 5.2),
            defender("CB", Card.EFFECT.FREEZE, 1.2, {"WR"}, 5.2),
            defender("S", Card.EFFECT.SLOW, 2.5, {"TE", "WR"}, 4.6),
            defender("S", Card.EFFECT.REMOVE_YARDS, 1.5, {}, 4.6)
        }
    },

    {
        id = "special_teams",
        name = "Special Teams Specialist",
        description = "Field position and tactical play",
        signature = "Short Field",
        signatureDesc = "Start 15% closer to endzone (68 yards vs 80)",
        color = {0.3, 0.8, 0.3}, -- Green
        difficulty = "average", -- Average coach with semi-random upgrades

        -- Offensive lineup (11 players) - Balanced
        offensiveCards = {
            yardGen("QB", 4.0, 3.6),
            yardGen("RB", 2.8, 4.4),
            yardGen("RB", 2.8, 4.4),
            booster("OL", 18, {"QB", "RB"}, 4.0),
            booster("OL", 18, {"QB", "RB"}, 4.0),
            booster("OL", 18, {"QB", "RB"}, 4.0),
            booster("OL", 18, {"QB", "RB"}, 4.0),
            booster("OL", 18, {"QB", "RB"}, 4.0),
            yardGen("WR", 3.2, 5.0),
            yardGen("WR", 3.2, 5.0),
            booster("TE", 18, {"QB", "RB"}, 4.0)
        },

        -- Defensive lineup (11 players) - Balanced
        defensiveCards = {
            defender("DL", Card.EFFECT.SLOW, 2.0, {"QB"}, 3.8),
            defender("DL", Card.EFFECT.REMOVE_YARDS, 1.8, {}, 3.8),
            defender("DL", Card.EFFECT.SLOW, 2.0, {"QB"}, 3.8),
            defender("DL", Card.EFFECT.REMOVE_YARDS, 1.8, {}, 3.8),
            defender("LB", Card.EFFECT.FREEZE, 1.0, {"RB"}, 4.2),
            defender("LB", Card.EFFECT.SLOW, 2.0, {"OL"}, 4.2),
            defender("LB", Card.EFFECT.FREEZE, 1.0, {"RB"}, 4.2),
            defender("CB", Card.EFFECT.FREEZE, 1.0, {"WR"}, 5.0),
            defender("CB", Card.EFFECT.FREEZE, 1.0, {"WR"}, 5.0),
            defender("S", Card.EFFECT.SLOW, 2.0, {"TE", "WR"}, 4.4),
            defender("S", Card.EFFECT.SLOW, 2.0, {"TE", "WR"}, 4.4)
        }
    },

    {
        id = "ground_game",
        name = "Ground Game Coach",
        description = "Run-heavy, possession football",
        signature = "Pound the Rock",
        signatureDesc = "RBs gain +2 extra yards per action",
        color = {0.6, 0.4, 0.2}, -- Brown
        difficulty = "weak", -- Weak coach with random upgrades

        -- Offensive lineup (11 players) - Run-heavy
        offensiveCards = {
            yardGen("QB", 3.0, 3.4),    -- Run-first QB
            yardGen("RB", 3.5, 4.6),    -- Power back
            yardGen("RB", 3.5, 4.6),    -- Speed back
            booster("OL", 22, {"RB"}, 3.6),  -- Run-blocking specialist
            booster("OL", 22, {"RB"}, 3.6),
            booster("OL", 22, {"RB"}, 3.6),
            booster("OL", 20, {"RB"}, 3.6),
            booster("OL", 20, {"RB"}, 3.6),
            yardGen("WR", 2.8, 4.8),    -- Blocking WR
            yardGen("WR", 2.8, 4.8),
            booster("TE", 20, {"RB"}, 3.8)  -- Blocking TE
        },

        -- Defensive lineup (11 players) - Run-stuffing defense
        defensiveCards = {
            defender("DL", Card.EFFECT.SLOW, 2.0, {"RB"}, 3.6),
            defender("DL", Card.EFFECT.FREEZE, 1.0, {"OL"}, 3.4),
            defender("DL", Card.EFFECT.SLOW, 2.0, {"RB"}, 3.6),
            defender("DL", Card.EFFECT.FREEZE, 1.0, {"OL"}, 3.4),
            defender("LB", Card.EFFECT.FREEZE, 1.2, {"RB"}, 4.0),
            defender("LB", Card.EFFECT.SLOW, 2.5, {"RB", "OL"}, 4.0),
            defender("LB", Card.EFFECT.FREEZE, 1.2, {"RB"}, 4.0),
            defender("CB", Card.EFFECT.SLOW, 2.0, {"WR"}, 4.8),
            defender("CB", Card.EFFECT.SLOW, 2.0, {"WR"}, 4.8),
            defender("S", Card.EFFECT.SLOW, 2.0, {"TE"}, 4.2),
            defender("S", Card.EFFECT.REMOVE_YARDS, 1.5, {}, 4.2)
        }
    }
}

-- Get coach by ID
function Coach.getById(id)
    for _, coach in ipairs(Coach.types) do
        if coach.id == id then
            return coach
        end
    end
    return nil
end

-- Get random coach (for AI)
function Coach.getRandom()
    local index = love.math.random(1, #Coach.types)
    return Coach.types[index]
end

-- Create card instances from coach card definitions
-- Converts the card definition tables into actual Card instances
-- @param cardDefs table Array of card definitions (e.g., coachData.offensiveCards)
-- @return table Array of Card instances
function Coach.createCardSet(cardDefs)
    local cards = {}
    for i, cardDef in ipairs(cardDefs) do
        local card = Card:new(cardDef.position, cardDef.cardType, cardDef.stats)
        table.insert(cards, card)
    end
    return cards
end

-- Get star rating for coach difficulty
-- @param difficulty string "elite", "average", or "weak"
-- @return number Number of stars (1-5)
function Coach.getStarRating(difficulty)
    if difficulty == "elite" then
        return 5
    elseif difficulty == "average" then
        return 3
    elseif difficulty == "weak" then
        return 1
    end
    return 3 -- Default to average
end

-- Get difficulty string for display
-- @param difficulty string "elite", "average", or "weak"
-- @return string Display name
function Coach.getDifficultyName(difficulty)
    if difficulty == "elite" then
        return "Elite"
    elseif difficulty == "average" then
        return "Average"
    elseif difficulty == "weak" then
        return "Weak"
    end
    return "Average" -- Default
end

return Coach
