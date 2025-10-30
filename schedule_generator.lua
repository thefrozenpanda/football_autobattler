--- schedule_generator.lua
--- Schedule Generation for Regular Season and Playoffs
---
--- Generates a 17-week regular season schedule ensuring each team plays
--- every other team exactly once. Also generates playoff brackets based on
--- conference standings (top 6 teams per conference).
---
--- Dependencies: team.lua
--- Used by: season_manager.lua
--- LÖVE Callbacks: None

local ScheduleGenerator = {}

--- Generates a 17-week regular season schedule
--- Uses round-robin algorithm to ensure each team plays every other team once
--- @param teams table Array of all 18 teams
--- @return table Array of 17 weeks, each week contains array of match objects
function ScheduleGenerator.generateRegularSeason(teams)
    local schedule = {}

    -- Separate teams by conference for easier management
    local Team = require("team")
    local conferenceA = Team.getTeamsInConference(teams, "A")
    local conferenceB = Team.getTeamsInConference(teams, "B")

    -- Shuffle both conferences to randomize schedule
    conferenceA = ScheduleGenerator.shuffleArray(conferenceA)
    conferenceB = ScheduleGenerator.shuffleArray(conferenceB)

    -- Combine into single pool for round-robin
    local allTeams = {}
    for _, team in ipairs(conferenceA) do
        table.insert(allTeams, team)
    end
    for _, team in ipairs(conferenceB) do
        table.insert(allTeams, team)
    end

    -- Generate round-robin schedule (17 weeks for 18 teams)
    schedule = ScheduleGenerator.generateRoundRobin(allTeams)

    return schedule
end

--- Generates a round-robin tournament schedule
--- Uses the circle method algorithm for even number of teams
--- @param teams table Array of teams (must be even number)
--- @return table Array of weeks, each week contains array of matches
function ScheduleGenerator.generateRoundRobin(teams)
    local numTeams = #teams
    local numWeeks = numTeams - 1
    local schedule = {}

    -- Create a copy of teams array to rotate
    local teamRotation = {}
    for i, team in ipairs(teams) do
        teamRotation[i] = team
    end

    -- Generate schedule for each week
    for week = 1, numWeeks do
        local weekMatches = {}

        -- Pair teams for this week
        -- Team 1 stays fixed, others rotate
        for i = 1, numTeams / 2 do
            local homeIndex = i
            local awayIndex = numTeams - i + 1

            local homeTeam = teamRotation[homeIndex]
            local awayTeam = teamRotation[awayIndex]

            -- Alternate home/away to balance
            if week % 2 == 0 then
                homeTeam, awayTeam = awayTeam, homeTeam
            end

            table.insert(weekMatches, {
                homeTeam = homeTeam,
                awayTeam = awayTeam,
                week = week,
                played = false,
                homeScore = 0,
                awayScore = 0
            })
        end

        table.insert(schedule, weekMatches)

        -- Rotate teams (keep first team fixed, rotate others clockwise)
        local temp = teamRotation[numTeams]
        for i = numTeams, 3, -1 do
            teamRotation[i] = teamRotation[i - 1]
        end
        teamRotation[2] = temp
    end

    return schedule
end

--- Generates playoff bracket structure
--- Wild Card: Seeds 3-6 play (1-2 get bye week)
--- Divisional: Seeds 1-2 enter, play against Wild Card winners
--- Conference: Winners of Divisional rounds
--- Championship: Conference A winner vs Conference B winner
--- @param playoffTeamsA table Top 6 teams from Conference A (sorted by seed)
--- @param playoffTeamsB table Top 6 teams from Conference B (sorted by seed)
--- @return table Playoff bracket with rounds: wildcard, divisional, conference, championship
function ScheduleGenerator.generatePlayoffBracket(playoffTeamsA, playoffTeamsB)
    local bracket = {
        currentRound = "wildcard",

        -- Wild Card Round (Week 18)
        wildcard = {
            -- Conference A: #3 vs #6, #4 vs #5
            {homeTeam = playoffTeamsA[3], awayTeam = playoffTeamsA[6], conference = "A", played = false},
            {homeTeam = playoffTeamsA[4], awayTeam = playoffTeamsA[5], conference = "A", played = false},
            -- Conference B: #3 vs #6, #4 vs #5
            {homeTeam = playoffTeamsB[3], awayTeam = playoffTeamsB[6], conference = "B", played = false},
            {homeTeam = playoffTeamsB[4], awayTeam = playoffTeamsB[5], conference = "B", played = false}
        },

        -- Divisional Round (Week 19) - will be populated after Wild Card
        divisional = {},

        -- Conference Championship (Week 20) - will be populated after Divisional
        conference = {},

        -- Championship Game (Week 21) - will be populated after Conference
        championship = {},

        -- Track seeds for bracket progression
        seedsA = playoffTeamsA,
        seedsB = playoffTeamsB
    }

    return bracket
end

--- Advances playoff bracket to next round based on winners
--- @param bracket table The playoff bracket structure
--- @param results table Array of match results {homeTeam, awayTeam, homeScore, awayScore}
function ScheduleGenerator.advanceBracket(bracket, results)
    if bracket.currentRound == "wildcard" then
        -- Determine Wild Card winners
        local winnersA = {}
        local winnersB = {}

        for _, result in ipairs(results) do
            local winner = (result.homeScore > result.awayScore) and result.homeTeam or result.awayTeam

            if result.conference == "A" then
                table.insert(winnersA, winner)
            else
                table.insert(winnersB, winner)
            end
        end

        -- Set up Divisional Round
        -- #1 seed plays lowest remaining seed, #2 seed plays highest remaining seed
        bracket.divisional = {
            -- Conference A: #1 vs lowest seed, #2 vs highest seed
            {homeTeam = bracket.seedsA[1], awayTeam = ScheduleGenerator.getLowestSeed(winnersA, bracket.seedsA), conference = "A", played = false},
            {homeTeam = bracket.seedsA[2], awayTeam = ScheduleGenerator.getHighestSeed(winnersA, bracket.seedsA), conference = "A", played = false},
            -- Conference B: #1 vs lowest seed, #2 vs highest seed
            {homeTeam = bracket.seedsB[1], awayTeam = ScheduleGenerator.getLowestSeed(winnersB, bracket.seedsB), conference = "B", played = false},
            {homeTeam = bracket.seedsB[2], awayTeam = ScheduleGenerator.getHighestSeed(winnersB, bracket.seedsB), conference = "B", played = false}
        }

    elseif bracket.currentRound == "divisional" then
        -- Determine Divisional winners
        local winnersA = {}
        local winnersB = {}

        for _, result in ipairs(results) do
            local winner = (result.homeScore > result.awayScore) and result.homeTeam or result.awayTeam

            if result.conference == "A" then
                table.insert(winnersA, winner)
            else
                table.insert(winnersB, winner)
            end
        end

        -- Set up Conference Championships
        bracket.conference = {
            {homeTeam = winnersA[1], awayTeam = winnersA[2], conference = "A", played = false},
            {homeTeam = winnersB[1], awayTeam = winnersB[2], conference = "B", played = false}
        }

    elseif bracket.currentRound == "conference" then
        -- Determine Conference winners
        local championA = nil
        local championB = nil

        for _, result in ipairs(results) do
            local winner = (result.homeScore > result.awayScore) and result.homeTeam or result.awayTeam

            if result.conference == "A" then
                championA = winner
            else
                championB = winner
            end
        end

        -- Set up Championship Game
        bracket.championship = {
            {homeTeam = championA, awayTeam = championB, played = false}
        }
    end
end

--- Gets the lowest seed from winners array
--- @param winners table Array of winning teams
--- @param seeds table Array of all seeds in order
--- @return Team The lowest seed team
function ScheduleGenerator.getLowestSeed(winners, seeds)
    for i = #seeds, 1, -1 do
        for _, winner in ipairs(winners) do
            if seeds[i] == winner then
                return winner
            end
        end
    end
    return winners[1]
end

--- Gets the highest seed from winners array
--- @param winners table Array of winning teams
--- @param seeds table Array of all seeds in order
--- @return Team The highest seed team
function ScheduleGenerator.getHighestSeed(winners, seeds)
    for i = 1, #seeds do
        for _, winner in ipairs(winners) do
            if seeds[i] == winner then
                return winner
            end
        end
    end
    return winners[1]
end

--- Shuffles an array randomly (Fisher-Yates algorithm)
--- @param array table Array to shuffle
--- @return table Shuffled array (new copy)
function ScheduleGenerator.shuffleArray(array)
    local shuffled = {}
    for i, item in ipairs(array) do
        shuffled[i] = item
    end

    for i = #shuffled, 2, -1 do
        local j = math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    return shuffled
end

return ScheduleGenerator
