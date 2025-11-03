-- coach.lua
-- Defines the 4 head coach archetypes with full 11-man rosters

local Card = require("card")
local Coach = {}

-- Helper function to create yard generator with range
local function yardGen(pos, yardsMin, yardsMax, spd)
    return {position = pos, cardType = Card.TYPE.YARD_GENERATOR, stats = {yardsPerActionMin = yardsMin, yardsPerActionMax = yardsMax, speed = spd}}
end

-- Helper function to create booster with range
local function booster(pos, boostMin, boostMax, targets, spd)
    return {position = pos, cardType = Card.TYPE.BOOSTER, stats = {boostAmountMin = boostMin, boostAmountMax = boostMax, boostTargets = targets, speed = spd}}
end

-- Helper function to create defender with range
local function defender(pos, effect, strengthMin, strengthMax, targets, spd)
    return {position = pos, cardType = Card.TYPE.DEFENDER, stats = {effectType = effect, effectStrengthMin = strengthMin, effectStrengthMax = strengthMax, targetPositions = targets, speed = spd}}
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

        -- Offensive lineup (11 players) - Passing focused (ELITE - Wide ranges)
        offensiveCards = {
            yardGen("QB", 3.0, 6.5, 3.6),    -- Franchise QB: 3.0-6.5 yards
            yardGen("RB", 1.0, 4.0, 4.4),    -- Receiving back: 1.0-4.0 yards
            yardGen("RB", 1.0, 4.0, 4.4),
            booster("OL", 17, 33, {"QB"}, 4.0),  -- Center: 17-33% boost
            booster("OL", 12, 28, {"QB"}, 4.0),  -- Guard: 12-28% boost
            booster("OL", 12, 28, {"QB"}, 4.0),  -- Guard
            booster("OL", 10, 26, {"QB"}, 4.0),  -- Tackle: 10-26% boost
            booster("OL", 10, 26, {"QB"}, 4.0),  -- Tackle
            yardGen("WR", 1.5, 5.5, 5.2),    -- WR1: 1.5-5.5 yards
            yardGen("WR", 1.5, 5.5, 5.2),    -- WR2
            booster("TE", 7, 23, {"QB"}, 4.2) -- Blocking TE: 7-23% boost
        },

        -- Defensive lineup (11 players) - Balanced defense (ELITE)
        defensiveCards = {
            defender("DL", Card.EFFECT.SLOW, 1.2, 2.8, {"QB"}, 3.8),
            defender("DL", Card.EFFECT.REMOVE_YARDS, 0.7, 2.3, {}, 3.6),
            defender("DL", Card.EFFECT.SLOW, 1.2, 2.8, {"QB"}, 3.8),
            defender("DL", Card.EFFECT.REMOVE_YARDS, 0.7, 2.3, {}, 3.6),
            defender("LB", Card.EFFECT.SLOW, 1.2, 2.8, {"RB", "OL"}, 4.2),
            defender("LB", Card.EFFECT.FREEZE, 0.4, 1.6, {"RB"}, 4.0),
            defender("LB", Card.EFFECT.SLOW, 1.2, 2.8, {"OL"}, 4.2),
            defender("CB", Card.EFFECT.FREEZE, 0.4, 1.6, {"WR"}, 5.0),
            defender("CB", Card.EFFECT.FREEZE, 0.4, 1.6, {"WR"}, 5.0),
            defender("S", Card.EFFECT.SLOW, 1.2, 2.8, {"TE", "WR"}, 4.4),
            defender("S", Card.EFFECT.SLOW, 1.2, 2.8, {"TE", "WR"}, 4.4)
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

        -- Offensive lineup (11 players) - Conservative offense (ELITE)
        offensiveCards = {
            yardGen("QB", 1.5, 5.5, 3.4),    -- Game manager QB: 1.5-5.5 yards
            yardGen("RB", 1.0, 5.0, 4.2),    -- 1.0-5.0 yards
            yardGen("RB", 1.0, 5.0, 4.2),
            booster("OL", 12, 28, {"QB", "RB"}, 3.8),  -- 12-28% boost
            booster("OL", 10, 26, {"QB", "RB"}, 3.8),  -- 10-26% boost
            booster("OL", 10, 26, {"QB", "RB"}, 3.8),
            booster("OL", 7, 23, {"RB"}, 3.8),  -- 7-23% boost
            booster("OL", 7, 23, {"RB"}, 3.8),
            yardGen("WR", 1.0, 5.0, 4.8),    -- 1.0-5.0 yards
            yardGen("WR", 1.0, 5.0, 4.8),
            yardGen("TE", 0.5, 4.5, 4.0)     -- Receiving TE: 0.5-4.5 yards
        },

        -- Defensive lineup (11 players) - DOMINANT defense (ELITE - Wide ranges)
        defensiveCards = {
            defender("DL", Card.EFFECT.REMOVE_YARDS, 1.0, 3.0, {}, 3.6),
            defender("DL", Card.EFFECT.SLOW, 1.5, 3.5, {"QB"}, 3.8),
            defender("DL", Card.EFFECT.REMOVE_YARDS, 1.0, 3.0, {}, 3.6),
            defender("DL", Card.EFFECT.SLOW, 1.5, 3.5, {"QB"}, 3.8),
            defender("LB", Card.EFFECT.FREEZE, 0.5, 2.0, {"RB", "OL"}, 4.0),
            defender("LB", Card.EFFECT.SLOW, 1.5, 3.5, {"RB"}, 4.2),
            defender("LB", Card.EFFECT.FREEZE, 0.5, 2.0, {"OL"}, 4.0),
            defender("CB", Card.EFFECT.FREEZE, 0.5, 2.0, {"WR"}, 5.2),
            defender("CB", Card.EFFECT.FREEZE, 0.5, 2.0, {"WR"}, 5.2),
            defender("S", Card.EFFECT.SLOW, 1.5, 3.5, {"TE", "WR"}, 4.6),
            defender("S", Card.EFFECT.REMOVE_YARDS, 0.7, 2.3, {}, 4.6)
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

        -- Offensive lineup (11 players) - Balanced (AVERAGE - Medium ranges)
        offensiveCards = {
            yardGen("QB", 2.5, 5.5, 3.6),    -- 2.5-5.5 yards
            yardGen("RB", 1.5, 4.5, 4.4),    -- 1.5-4.5 yards
            yardGen("RB", 1.5, 4.5, 4.4),
            booster("OL", 12, 24, {"QB", "RB"}, 4.0),  -- 12-24% boost
            booster("OL", 12, 24, {"QB", "RB"}, 4.0),
            booster("OL", 12, 24, {"QB", "RB"}, 4.0),
            booster("OL", 12, 24, {"QB", "RB"}, 4.0),
            booster("OL", 12, 24, {"QB", "RB"}, 4.0),
            yardGen("WR", 1.7, 4.7, 5.0),    -- 1.7-4.7 yards
            yardGen("WR", 1.7, 4.7, 5.0),
            booster("TE", 12, 24, {"QB", "RB"}, 4.0)  -- 12-24% boost
        },

        -- Defensive lineup (11 players) - Balanced (AVERAGE - Medium ranges)
        defensiveCards = {
            defender("DL", Card.EFFECT.SLOW, 1.4, 2.6, {"QB"}, 3.8),
            defender("DL", Card.EFFECT.REMOVE_YARDS, 1.0, 2.6, {}, 3.8),
            defender("DL", Card.EFFECT.SLOW, 1.4, 2.6, {"QB"}, 3.8),
            defender("DL", Card.EFFECT.REMOVE_YARDS, 1.0, 2.6, {}, 3.8),
            defender("LB", Card.EFFECT.FREEZE, 0.5, 1.5, {"RB"}, 4.2),
            defender("LB", Card.EFFECT.SLOW, 1.4, 2.6, {"OL"}, 4.2),
            defender("LB", Card.EFFECT.FREEZE, 0.5, 1.5, {"RB"}, 4.2),
            defender("CB", Card.EFFECT.FREEZE, 0.5, 1.5, {"WR"}, 5.0),
            defender("CB", Card.EFFECT.FREEZE, 0.5, 1.5, {"WR"}, 5.0),
            defender("S", Card.EFFECT.SLOW, 1.4, 2.6, {"TE", "WR"}, 4.4),
            defender("S", Card.EFFECT.SLOW, 1.4, 2.6, {"TE", "WR"}, 4.4)
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

        -- Offensive lineup (11 players) - Run-heavy (WEAK - Narrow ranges)
        offensiveCards = {
            yardGen("QB", 2.0, 4.2, 3.4),    -- Run-first QB: 2.0-4.2 yards
            yardGen("RB", 2.5, 4.8, 4.6),    -- Power back: 2.5-4.8 yards
            yardGen("RB", 2.5, 4.8, 4.6),    -- Speed back
            booster("OL", 17, 27, {"RB"}, 3.6),  -- Run-blocking specialist: 17-27% boost
            booster("OL", 17, 27, {"RB"}, 3.6),
            booster("OL", 17, 27, {"RB"}, 3.6),
            booster("OL", 15, 25, {"RB"}, 3.6),  -- 15-25% boost
            booster("OL", 15, 25, {"RB"}, 3.6),
            yardGen("WR", 1.8, 4.0, 4.8),    -- Blocking WR: 1.8-4.0 yards
            yardGen("WR", 1.8, 4.0, 4.8),
            booster("TE", 15, 25, {"RB"}, 3.8)  -- Blocking TE: 15-25% boost
        },

        -- Defensive lineup (11 players) - Run-stuffing defense (WEAK - Narrow ranges)
        defensiveCards = {
            defender("DL", Card.EFFECT.SLOW, 1.5, 2.5, {"RB"}, 3.6),
            defender("DL", Card.EFFECT.FREEZE, 0.7, 1.3, {"OL"}, 3.4),
            defender("DL", Card.EFFECT.SLOW, 1.5, 2.5, {"RB"}, 3.6),
            defender("DL", Card.EFFECT.FREEZE, 0.7, 1.3, {"OL"}, 3.4),
            defender("LB", Card.EFFECT.FREEZE, 0.8, 1.6, {"RB"}, 4.0),
            defender("LB", Card.EFFECT.SLOW, 1.8, 3.2, {"RB", "OL"}, 4.0),
            defender("LB", Card.EFFECT.FREEZE, 0.8, 1.6, {"RB"}, 4.0),
            defender("CB", Card.EFFECT.SLOW, 1.5, 2.5, {"WR"}, 4.8),
            defender("CB", Card.EFFECT.SLOW, 1.5, 2.5, {"WR"}, 4.8),
            defender("S", Card.EFFECT.SLOW, 1.5, 2.5, {"TE"}, 4.2),
            defender("S", Card.EFFECT.REMOVE_YARDS, 0.8, 2.2, {}, 4.2)
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
