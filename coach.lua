-- coach.lua
-- Defines the 4 head coach archetypes

local Coach = {}

-- Coach type definitions
Coach.types = {
    {
        id = "offensive_guru",
        name = "Offensive Guru",
        description = "High-scoring, aggressive offense",
        signature = "No Huddle",
        signatureDesc = "Reduces offensive cooldowns by 15%",
        color = {0.9, 0.3, 0.2}, -- Red

        -- Offensive lineup
        offensiveCards = {
            {position = "QB", power = 140, speed = 1.7},
            {position = "WR", power = 110, speed = 2.8},
            {position = "WR", power = 110, speed = 2.8},
            {position = "TE", power = 120, speed = 2.0}
        },

        -- Defensive lineup (weaker defense)
        defensiveCards = {
            {position = "CB", power = 95, speed = 2.4},
            {position = "CB", power = 95, speed = 2.4},
            {position = "S", power = 100, speed = 2.0},
            {position = "LB", power = 105, speed = 1.8}
        }
    },

    {
        id = "defensive_mastermind",
        name = "Defensive Mastermind",
        description = "Defense wins championships",
        signature = "Blitz Package",
        signatureDesc = "Defensive surge every 8 seconds",
        color = {0.2, 0.4, 0.9}, -- Blue

        -- Offensive lineup (weaker offense)
        offensiveCards = {
            {position = "QB", power = 110, speed = 1.6},
            {position = "RB", power = 105, speed = 2.0},
            {position = "TE", power = 100, speed = 1.9},
            {position = "WR", power = 95, speed = 2.5}
        },

        -- Defensive lineup (stronger defense)
        defensiveCards = {
            {position = "LB", power = 135, speed = 2.1},
            {position = "LB", power = 125, speed = 2.0},
            {position = "S", power = 130, speed = 2.2},
            {position = "CB", power = 115, speed = 2.5}
        }
    },

    {
        id = "special_teams",
        name = "Special Teams Specialist",
        description = "Field position and special plays",
        signature = "Hidden Yardage",
        signatureDesc = "Bonus momentum every 6 seconds",
        color = {0.3, 0.8, 0.3}, -- Green

        -- Balanced but unique lineup
        offensiveCards = {
            {position = "QB", power = 115, speed = 1.9},
            {position = "RB", power = 110, speed = 2.3},
            {position = "WR", power = 105, speed = 2.6},
            {position = "K", power = 100, speed = 1.5}  -- Kicker unique to this coach
        },

        defensiveCards = {
            {position = "LB", power = 115, speed = 2.0},
            {position = "CB", power = 110, speed = 2.4},
            {position = "S", power = 115, speed = 2.1},
            {position = "P", power = 100, speed = 1.6}  -- Punter unique to this coach
        }
    },

    {
        id = "ground_game",
        name = "Ground Game Coach",
        description = "Run-heavy, possession football",
        signature = "Pound the Rock",
        signatureDesc = "Running plays gain power over time",
        color = {0.6, 0.4, 0.2}, -- Brown

        -- Run-heavy lineup
        offensiveCards = {
            {position = "RB", power = 130, speed = 2.4},
            {position = "RB", power = 120, speed = 2.2},
            {position = "FB", power = 115, speed = 1.8},  -- Fullback unique to this coach
            {position = "TE", power = 125, speed = 2.0}
        },

        -- Balanced defense
        defensiveCards = {
            {position = "DT", power = 125, speed = 1.7},  -- Defensive Tackle
            {position = "LB", power = 120, speed = 2.0},
            {position = "LB", power = 115, speed = 2.1},
            {position = "S", power = 110, speed = 2.2}
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
