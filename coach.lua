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

        -- Offensive lineup (11 players) - Passing focused
        offensiveCards = {
            yardGen("QB", 4.5, 1.8),    -- Franchise QB
            yardGen("RB", 2.5, 2.2),    -- Receiving back
            yardGen("RB", 2.5, 2.2),
            booster("OL", 25, {"QB"}, 2.0),  -- Center
            booster("OL", 20, {"QB"}, 2.0),  -- Guard
            booster("OL", 20, {"QB"}, 2.0),  -- Guard
            booster("OL", 18, {"QB"}, 2.0),  -- Tackle
            booster("OL", 18, {"QB"}, 2.0),  -- Tackle
            yardGen("WR", 3.5, 2.6),    -- WR1
            yardGen("WR", 3.5, 2.6),    -- WR2
            booster("TE", 15, {"QB"}, 2.1) -- Blocking TE
        },

        -- Defensive lineup (11 players) - Balanced defense
        defensiveCards = {
            defender("DL", Card.EFFECT.SLOW, 2.0, {"QB"}, 1.9),
            defender("DL", Card.EFFECT.REMOVE_YARDS, 1.5, {}, 1.8),
            defender("DL", Card.EFFECT.SLOW, 2.0, {"QB"}, 1.9),
            defender("DL", Card.EFFECT.REMOVE_YARDS, 1.5, {}, 1.8),
            defender("LB", Card.EFFECT.SLOW, 2.0, {"RB", "OL"}, 2.1),
            defender("LB", Card.EFFECT.FREEZE, 1.0, {"RB"}, 2.0),
            defender("LB", Card.EFFECT.SLOW, 2.0, {"OL"}, 2.1),
            defender("CB", Card.EFFECT.FREEZE, 1.0, {"WR"}, 2.5),
            defender("CB", Card.EFFECT.FREEZE, 1.0, {"WR"}, 2.5),
            defender("S", Card.EFFECT.SLOW, 2.0, {"TE", "WR"}, 2.2),
            defender("S", Card.EFFECT.SLOW, 2.0, {"TE", "WR"}, 2.2)
        }
    },

    {
        id = "defensive_mastermind",
        name = "Defensive Mastermind",
        description = "Defense wins championships",
        signature = "Blitz Package",
        signatureDesc = "5% chance to remove 2 yards on defensive action",
        color = {0.2, 0.4, 0.9}, -- Blue

        -- Offensive lineup (11 players) - Conservative offense
        offensiveCards = {
            yardGen("QB", 3.5, 1.7),    -- Game manager QB
            yardGen("RB", 3.0, 2.1),
            yardGen("RB", 3.0, 2.1),
            booster("OL", 20, {"QB", "RB"}, 1.9),
            booster("OL", 18, {"QB", "RB"}, 1.9),
            booster("OL", 18, {"QB", "RB"}, 1.9),
            booster("OL", 15, {"RB"}, 1.9),
            booster("OL", 15, {"RB"}, 1.9),
            yardGen("WR", 3.0, 2.4),
            yardGen("WR", 3.0, 2.4),
            yardGen("TE", 2.5, 2.0)     -- Receiving TE
        },

        -- Defensive lineup (11 players) - DOMINANT defense
        defensiveCards = {
            defender("DL", Card.EFFECT.REMOVE_YARDS, 2.0, {}, 1.8),
            defender("DL", Card.EFFECT.SLOW, 2.5, {"QB"}, 1.9),
            defender("DL", Card.EFFECT.REMOVE_YARDS, 2.0, {}, 1.8),
            defender("DL", Card.EFFECT.SLOW, 2.5, {"QB"}, 1.9),
            defender("LB", Card.EFFECT.FREEZE, 1.2, {"RB", "OL"}, 2.0),
            defender("LB", Card.EFFECT.SLOW, 2.5, {"RB"}, 2.1),
            defender("LB", Card.EFFECT.FREEZE, 1.2, {"OL"}, 2.0),
            defender("CB", Card.EFFECT.FREEZE, 1.2, {"WR"}, 2.6),
            defender("CB", Card.EFFECT.FREEZE, 1.2, {"WR"}, 2.6),
            defender("S", Card.EFFECT.SLOW, 2.5, {"TE", "WR"}, 2.3),
            defender("S", Card.EFFECT.REMOVE_YARDS, 1.5, {}, 2.3)
        }
    },

    {
        id = "special_teams",
        name = "Special Teams Specialist",
        description = "Field position and tactical play",
        signature = "Short Field",
        signatureDesc = "Start 15% closer to endzone (68 yards vs 80)",
        color = {0.3, 0.8, 0.3}, -- Green

        -- Offensive lineup (11 players) - Balanced
        offensiveCards = {
            yardGen("QB", 4.0, 1.8),
            yardGen("RB", 2.8, 2.2),
            yardGen("RB", 2.8, 2.2),
            booster("OL", 18, {"QB", "RB"}, 2.0),
            booster("OL", 18, {"QB", "RB"}, 2.0),
            booster("OL", 18, {"QB", "RB"}, 2.0),
            booster("OL", 18, {"QB", "RB"}, 2.0),
            booster("OL", 18, {"QB", "RB"}, 2.0),
            yardGen("WR", 3.2, 2.5),
            yardGen("WR", 3.2, 2.5),
            booster("TE", 18, {"QB", "RB"}, 2.0)
        },

        -- Defensive lineup (11 players) - Balanced
        defensiveCards = {
            defender("DL", Card.EFFECT.SLOW, 2.0, {"QB"}, 1.9),
            defender("DL", Card.EFFECT.REMOVE_YARDS, 1.8, {}, 1.9),
            defender("DL", Card.EFFECT.SLOW, 2.0, {"QB"}, 1.9),
            defender("DL", Card.EFFECT.REMOVE_YARDS, 1.8, {}, 1.9),
            defender("LB", Card.EFFECT.FREEZE, 1.0, {"RB"}, 2.1),
            defender("LB", Card.EFFECT.SLOW, 2.0, {"OL"}, 2.1),
            defender("LB", Card.EFFECT.FREEZE, 1.0, {"RB"}, 2.1),
            defender("CB", Card.EFFECT.FREEZE, 1.0, {"WR"}, 2.5),
            defender("CB", Card.EFFECT.FREEZE, 1.0, {"WR"}, 2.5),
            defender("S", Card.EFFECT.SLOW, 2.0, {"TE", "WR"}, 2.2),
            defender("S", Card.EFFECT.SLOW, 2.0, {"TE", "WR"}, 2.2)
        }
    },

    {
        id = "ground_game",
        name = "Ground Game Coach",
        description = "Run-heavy, possession football",
        signature = "Pound the Rock",
        signatureDesc = "RBs gain +2 extra yards per action",
        color = {0.6, 0.4, 0.2}, -- Brown

        -- Offensive lineup (11 players) - Run-heavy
        offensiveCards = {
            yardGen("QB", 3.0, 1.7),    -- Run-first QB
            yardGen("RB", 3.5, 2.3),    -- Power back
            yardGen("RB", 3.5, 2.3),    -- Speed back
            booster("OL", 22, {"RB"}, 1.8),  -- Run-blocking specialist
            booster("OL", 22, {"RB"}, 1.8),
            booster("OL", 22, {"RB"}, 1.8),
            booster("OL", 20, {"RB"}, 1.8),
            booster("OL", 20, {"RB"}, 1.8),
            yardGen("WR", 2.8, 2.4),    -- Blocking WR
            yardGen("WR", 2.8, 2.4),
            booster("TE", 20, {"RB"}, 1.9)  -- Blocking TE
        },

        -- Defensive lineup (11 players) - Run-stuffing defense
        defensiveCards = {
            defender("DL", Card.EFFECT.SLOW, 2.0, {"RB"}, 1.8),
            defender("DL", Card.EFFECT.FREEZE, 1.0, {"OL"}, 1.7),
            defender("DL", Card.EFFECT.SLOW, 2.0, {"RB"}, 1.8),
            defender("DL", Card.EFFECT.FREEZE, 1.0, {"OL"}, 1.7),
            defender("LB", Card.EFFECT.FREEZE, 1.2, {"RB"}, 2.0),
            defender("LB", Card.EFFECT.SLOW, 2.5, {"RB", "OL"}, 2.0),
            defender("LB", Card.EFFECT.FREEZE, 1.2, {"RB"}, 2.0),
            defender("CB", Card.EFFECT.SLOW, 2.0, {"WR"}, 2.4),
            defender("CB", Card.EFFECT.SLOW, 2.0, {"WR"}, 2.4),
            defender("S", Card.EFFECT.SLOW, 2.0, {"TE"}, 2.1),
            defender("S", Card.EFFECT.REMOVE_YARDS, 1.5, {}, 2.1)
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

return Coach
