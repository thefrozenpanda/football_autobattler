--- team.lua
--- Team Data Structure and League Configuration
---
--- Represents a football team in the league (player or AI).
--- Tracks team name, conference, coach archetype, record, and statistics.
--- Manages the 18-team league structure split into two conferences.
---
--- Dependencies: None
--- Used by: season_manager.lua, schedule_generator.lua
--- LÖVE Callbacks: None

local Team = {}
Team.__index = Team

-- Conference A Team Names (9 teams)
Team.CONFERENCE_A = {
    "Green Bay Packagers",
    "New England Chowder Heads",
    "Kansas City Chefs",
    "Buffalo Wingmen",
    "Miami Swim Team",
    "Pittsburgh Steelworkers",
    "Baltimore Raven-claws",
    "Cincinnati Zoo Cats",
    "Cleveland Brownies"
}

-- Conference B Team Names (9 teams)
Team.CONFERENCE_B = {
    "Dallas Cow-Folks",
    "San Francisco Gold Diggers",
    "Seattle Sea-Folks",
    "Los Angeles Ramblers",
    "Arizona Card Sharks",
    "New Orleans Second Liners",
    "Tampa Bay Ship Captains",
    "Philadelphia Cheese Steaks",
    "New York Really Tall People"
}

--- Creates a new team
--- @param name string Team name
--- @param conference string "A" or "B"
--- @param coachId string Coach archetype ID from coach.lua
--- @param isPlayer boolean Whether this is the player's team
--- @return Team New team instance
function Team:new(name, conference, coachId, isPlayer)
    local t = {
        name = name,
        conference = conference,
        coachId = coachId,
        isPlayer = isPlayer or false,

        -- Season record
        wins = 0,
        losses = 0,

        -- Statistics for tiebreakers
        pointsFor = 0,      -- Total points scored
        pointsAgainst = 0,  -- Total points allowed

        -- Head-to-head results (table indexed by opponent team name)
        -- Value: "W", "L", or nil (not played yet)
        headToHead = {},

        -- Training budget (for all teams)
        cash = 0,

        -- Roster (cards will be populated from coach)
        offensiveCards = {},
        defensiveCards = {},
        benchCards = {},
        kicker = nil,  -- Special teams kicker
        punter = nil   -- Special teams punter
    }

    setmetatable(t, Team)
    return t
end

--- Records a win for this team
--- Updates wins and point differential
--- @param pointsFor number Points scored by this team
--- @param pointsAgainst number Points scored by opponent
--- @param opponentName string Name of opponent team (for head-to-head tracking)
function Team:recordWin(pointsFor, pointsAgainst, opponentName)
    self.wins = self.wins + 1
    self.pointsFor = self.pointsFor + pointsFor
    self.pointsAgainst = self.pointsAgainst + pointsAgainst
    self.headToHead[opponentName] = "W"
end

--- Records a loss for this team
--- Updates losses and point differential
--- @param pointsFor number Points scored by this team
--- @param pointsAgainst number Points scored by opponent
--- @param opponentName string Name of opponent team (for head-to-head tracking)
function Team:recordLoss(pointsFor, pointsAgainst, opponentName)
    self.losses = self.losses + 1
    self.pointsFor = self.pointsFor + pointsFor
    self.pointsAgainst = self.pointsAgainst + pointsAgainst
    self.headToHead[opponentName] = "L"
end

--- Calculates point differential (used for tiebreakers)
--- @return number Point differential (positive is better)
function Team:getPointDifferential()
    return self.pointsFor - self.pointsAgainst
end

--- Gets the team's record as a formatted string
--- @return string Record in "W-L" format (e.g., "10-7")
function Team:getRecordString()
    return string.format("%d-%d", self.wins, self.losses)
end

--- Checks if this team beat another team head-to-head
--- @param opponentName string Name of opponent team
--- @return boolean|nil True if won, false if lost, nil if not played
function Team:beatTeam(opponentName)
    local result = self.headToHead[opponentName]
    if result == "W" then
        return true
    elseif result == "L" then
        return false
    else
        return nil
    end
end

--- Awards cash to the team (all teams)
--- @param amount number Cash to award
function Team:awardCash(amount)
    self.cash = self.cash + amount
end

--- Deducts cash from the team (all teams)
--- @param amount number Cash to deduct
--- @return boolean True if sufficient cash, false otherwise
function Team:spendCash(amount)
    if self.cash >= amount then
        self.cash = self.cash - amount
        return true
    end

    return false
end

--- Resets the team's season statistics
--- Used when starting a new season
function Team:resetSeason()
    self.wins = 0
    self.losses = 0
    self.pointsFor = 0
    self.pointsAgainst = 0
    self.headToHead = {}

    -- Reset card statistics
    local function resetCardStats(cards)
        for _, card in ipairs(cards) do
            card.yardsGained = 0
            card.touchdownsScored = 0
            card.cardsBoosted = 0
            card.timesSlowed = 0
            card.timesFroze = 0
            card.yardsReduced = 0
        end
    end

    resetCardStats(self.offensiveCards)
    resetCardStats(self.defensiveCards)
    resetCardStats(self.benchCards)

    -- Reset special teams stats
    if self.kicker then
        self.kicker.yardsGained = 0
        self.kicker.touchdownsScored = 0
        self.kicker.cardsBoosted = 0
        self.kicker.timesSlowed = 0
        self.kicker.timesFroze = 0
        self.kicker.yardsReduced = 0
    end
    if self.punter then
        self.punter.yardsGained = 0
        self.punter.touchdownsScored = 0
        self.punter.cardsBoosted = 0
        self.punter.timesSlowed = 0
        self.punter.timesFroze = 0
        self.punter.yardsReduced = 0
    end
end

--- Generates all 18 teams for the league
--- Player team will be marked after coach selection
--- @return table Array of 18 Team instances (9 per conference)
function Team.generateLeague()
    local teams = {}
    local Coach = require("coach")

    -- Generate Conference A teams (all AI initially)
    for i, name in ipairs(Team.CONFERENCE_A) do
        local randomCoach = Coach.getRandom()
        local team = Team:new(name, "A", randomCoach.id, false)

        -- Populate cards from coach
        team.offensiveCards = Coach.createCardSet(randomCoach.offensiveCards)
        team.defensiveCards = Coach.createCardSet(randomCoach.defensiveCards)
        team.benchCards = {}  -- AI teams start with empty bench
        team.cash = 100  -- AI teams start with same cash as player

        -- Create special teams cards
        local Card = require("card")
        if randomCoach.kicker then
            team.kicker = Card:new(randomCoach.kicker.position, randomCoach.kicker.cardType, randomCoach.kicker.stats)
        end
        if randomCoach.punter then
            team.punter = Card:new(randomCoach.punter.position, randomCoach.punter.cardType, randomCoach.punter.stats)
        end

        table.insert(teams, team)
    end

    -- Generate Conference B teams (all AI initially)
    for i, name in ipairs(Team.CONFERENCE_B) do
        local randomCoach = Coach.getRandom()
        local team = Team:new(name, "B", randomCoach.id, false)

        -- Populate cards from coach
        team.offensiveCards = Coach.createCardSet(randomCoach.offensiveCards)
        team.defensiveCards = Coach.createCardSet(randomCoach.defensiveCards)
        team.benchCards = {}  -- AI teams start with empty bench
        team.cash = 100  -- AI teams start with same cash as player

        -- Create special teams cards
        local Card = require("card")
        if randomCoach.kicker then
            team.kicker = Card:new(randomCoach.kicker.position, randomCoach.kicker.cardType, randomCoach.kicker.stats)
        end
        if randomCoach.punter then
            team.punter = Card:new(randomCoach.punter.position, randomCoach.punter.cardType, randomCoach.punter.stats)
        end

        table.insert(teams, team)
    end

    return teams
end

--- Gets all teams in a specific conference
--- @param teams table Array of all teams
--- @param conference string "A" or "B"
--- @return table Array of teams in the specified conference
function Team.getTeamsInConference(teams, conference)
    local conferenceTeams = {}

    for _, team in ipairs(teams) do
        if team.conference == conference then
            table.insert(conferenceTeams, team)
        end
    end

    return conferenceTeams
end

--- Sorts teams by playoff seeding criteria
--- 1. Best record (wins)
--- 2. Head-to-head result (if tied)
--- 3. Point differential (if still tied or no head-to-head)
--- 4. Random (if all else equal)
--- @param teams table Array of teams to sort
--- @return table Sorted array (best team first)
function Team.sortByStandings(teams)
    local sortedTeams = {}
    for _, team in ipairs(teams) do
        table.insert(sortedTeams, team)
    end

    table.sort(sortedTeams, function(a, b)
        -- Tiebreaker 1: Most wins
        if a.wins ~= b.wins then
            return a.wins > b.wins
        end

        -- Tiebreaker 2: Head-to-head result
        local aBeatsB = a:beatTeam(b.name)
        if aBeatsB ~= nil then
            return aBeatsB
        end

        -- Tiebreaker 3: Point differential
        local aDiff = a:getPointDifferential()
        local bDiff = b:getPointDifferential()
        if aDiff ~= bDiff then
            return aDiff > bDiff
        end

        -- Tiebreaker 4: Random (use name as tiebreaker for consistency)
        return a.name < b.name
    end)

    return sortedTeams
end

return Team
