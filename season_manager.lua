--- season_manager.lua
--- Season State Management
---
--- Manages the season lifecycle including regular season (17 weeks) and playoffs.
--- Tracks all 18 teams, schedules, current week, current phase, and playoff progression.
--- Handles phase transitions: Training → Preparation → Match → (next week)
---
--- Dependencies: team.lua, schedule_generator.lua
--- Used by: main.lua
--- LÖVE Callbacks: None

local SeasonManager = {}

local Team = require("team")
local ScheduleGenerator = require("schedule_generator")

-- Season state
SeasonManager.teams = {}              -- All 18 teams
SeasonManager.playerTeam = nil        -- Reference to player's team
SeasonManager.schedule = {}           -- Regular season schedule (17 weeks)
SeasonManager.playoffBracket = {}     -- Playoff bracket structure

-- Current week and phase
SeasonManager.currentWeek = 1         -- Week 1-17 (regular), 18-21 (playoffs)
SeasonManager.currentPhase = "preparation"  -- Phases: "training", "preparation", "match"
SeasonManager.inPlayoffs = false      -- Flag for playoff mode

-- Match result tracking
SeasonManager.lastMatchResult = nil   -- {playerScore, aiScore, playerWon, mvpOffense, mvpDefense}

-- Phase identifiers
SeasonManager.PHASE = {
    TRAINING = "training",
    PREPARATION = "preparation",
    MATCH = "match"
}

--- Initializes a new season
--- @param playerCoachId string Coach ID selected by player
--- @param playerTeamName string Team name chosen by player
function SeasonManager.startNewSeason(playerCoachId, playerTeamName)
    -- Generate all 18 teams
    SeasonManager.teams = Team.generateLeague()

    -- Find a team to replace with player's team (pick random team from Conference A)
    local conferenceATeams = Team.getTeamsInConference(SeasonManager.teams, "A")
    local replaceIndex = math.random(1, #conferenceATeams)

    -- Create player team
    local playerTeam = Team:new(playerTeamName, "A", playerCoachId, true)

    -- Load player's coach cards
    local Coach = require("coach")
    local coachData = Coach.getById(playerCoachId)
    playerTeam.offensiveCards = Coach.createCardSet(coachData.offensiveCards)
    playerTeam.defensiveCards = Coach.createCardSet(coachData.defensiveCards)
    playerTeam.benchCards = {}  -- Start with empty bench

    -- Replace a random Conference A team with player team
    for i, team in ipairs(SeasonManager.teams) do
        if team.conference == "A" and replaceIndex > 0 then
            replaceIndex = replaceIndex - 1
            if replaceIndex == 0 then
                SeasonManager.teams[i] = playerTeam
                SeasonManager.playerTeam = playerTeam
                break
            end
        end
    end

    -- Generate 17-week regular season schedule
    SeasonManager.schedule = ScheduleGenerator.generateRegularSeason(SeasonManager.teams)

    -- Initialize season state
    SeasonManager.currentWeek = 1
    SeasonManager.currentPhase = SeasonManager.PHASE.PREPARATION
    SeasonManager.inPlayoffs = false
    SeasonManager.playoffBracket = {}
    SeasonManager.lastMatchResult = nil
end

--- Gets the current week's matchup for the player
--- @return table|nil Match data {playerTeam, opponentTeam, weekNumber} or nil if no match
function SeasonManager.getPlayerMatch()
    if SeasonManager.inPlayoffs then
        return SeasonManager.getPlayerPlayoffMatch()
    end

    -- Find player's match in current week
    local weekSchedule = SeasonManager.schedule[SeasonManager.currentWeek]
    if not weekSchedule then
        return nil
    end

    for _, match in ipairs(weekSchedule) do
        if match.homeTeam == SeasonManager.playerTeam or match.awayTeam == SeasonManager.playerTeam then
            local opponent = (match.homeTeam == SeasonManager.playerTeam) and match.awayTeam or match.homeTeam
            return {
                playerTeam = SeasonManager.playerTeam,
                opponentTeam = opponent,
                weekNumber = SeasonManager.currentWeek,
                isHome = (match.homeTeam == SeasonManager.playerTeam)
            }
        end
    end

    return nil
end

--- Advances to the training phase
--- Awards cash to player based on last match result
function SeasonManager.goToTraining()
    SeasonManager.currentPhase = SeasonManager.PHASE.TRAINING

    -- Award cash based on match result
    if SeasonManager.lastMatchResult then
        if SeasonManager.lastMatchResult.playerWon then
            SeasonManager.playerTeam:awardCash(150)
        else
            SeasonManager.playerTeam:awardCash(100)
        end
    end
end

--- Advances to the preparation phase
function SeasonManager.goToPreparation()
    SeasonManager.currentPhase = SeasonManager.PHASE.PREPARATION
end

--- Advances to the match phase
function SeasonManager.goToMatch()
    SeasonManager.currentPhase = SeasonManager.PHASE.MATCH
end

--- Records the result of a match
--- @param homeTeam Team The home team
--- @param awayTeam Team The away team
--- @param homeScore number Home team score
--- @param awayScore number Away team score
function SeasonManager.recordMatchResult(homeTeam, awayTeam, homeScore, awayScore)
    if homeScore > awayScore then
        homeTeam:recordWin(homeScore, awayScore, awayTeam.name)
        awayTeam:recordLoss(awayScore, homeScore, homeTeam.name)
    else
        awayTeam:recordWin(awayScore, homeScore, homeTeam.name)
        homeTeam:recordLoss(homeScore, awayScore, awayTeam.name)
    end

    -- Track if this was player's match
    if homeTeam == SeasonManager.playerTeam or awayTeam == SeasonManager.playerTeam then
        SeasonManager.lastMatchResult = {
            playerScore = (homeTeam == SeasonManager.playerTeam) and homeScore or awayScore,
            aiScore = (homeTeam == SeasonManager.playerTeam) and awayScore or homeScore,
            playerWon = (homeTeam == SeasonManager.playerTeam) and homeScore > awayScore or awayScore > homeScore,
            mvpOffense = nil,  -- Will be set by match.lua
            mvpDefense = nil   -- Will be set by match.lua
        }
    end
end

--- Simulates all AI vs AI matches for the current week
--- Runs full match simulation for each non-player game
function SeasonManager.simulateWeek()
    local weekSchedule = SeasonManager.schedule[SeasonManager.currentWeek]
    if not weekSchedule then
        return
    end

    local match = require("match")

    for _, matchData in ipairs(weekSchedule) do
        -- Skip player's match
        if matchData.homeTeam ~= SeasonManager.playerTeam and matchData.awayTeam ~= SeasonManager.playerTeam then
            -- Simulate full match (run actual match logic in background)
            local homeScore, awayScore = match.simulateAIMatch(matchData.homeTeam, matchData.awayTeam)
            SeasonManager.recordMatchResult(matchData.homeTeam, matchData.awayTeam, homeScore, awayScore)
        end
    end
end

--- Advances to the next week
--- If regular season complete, generates playoff bracket
function SeasonManager.nextWeek()
    SeasonManager.currentWeek = SeasonManager.currentWeek + 1

    -- Check if regular season is complete
    if SeasonManager.currentWeek > 17 and not SeasonManager.inPlayoffs then
        SeasonManager.startPlayoffs()
    elseif SeasonManager.inPlayoffs then
        SeasonManager.advancePlayoffs()
    else
        -- Start next regular season week with preparation phase
        SeasonManager.currentPhase = SeasonManager.PHASE.PREPARATION
        SeasonManager.lastMatchResult = nil
    end
end

--- Starts the playoff system
--- Determines top 6 teams per conference and generates bracket
function SeasonManager.startPlayoffs()
    SeasonManager.inPlayoffs = true
    SeasonManager.currentWeek = 18  -- Playoffs start at week 18

    -- Get conference standings
    local conferenceA = Team.getTeamsInConference(SeasonManager.teams, "A")
    local conferenceB = Team.getTeamsInConference(SeasonManager.teams, "B")

    local standingsA = Team.sortByStandings(conferenceA)
    local standingsB = Team.sortByStandings(conferenceB)

    -- Top 6 per conference make playoffs
    local playoffTeamsA = {standingsA[1], standingsA[2], standingsA[3], standingsA[4], standingsA[5], standingsA[6]}
    local playoffTeamsB = {standingsB[1], standingsB[2], standingsB[3], standingsB[4], standingsB[5], standingsB[6]}

    -- Check if player made playoffs
    local playerMadePlayoffs = false
    for _, team in ipairs(playoffTeamsA) do
        if team == SeasonManager.playerTeam then
            playerMadePlayoffs = true
            break
        end
    end
    for _, team in ipairs(playoffTeamsB) do
        if team == SeasonManager.playerTeam then
            playerMadePlayoffs = true
            break
        end
    end

    if not playerMadePlayoffs then
        -- Player missed playoffs - end season
        SeasonManager.currentPhase = "season_end"
        return
    end

    -- Generate playoff bracket
    SeasonManager.playoffBracket = ScheduleGenerator.generatePlayoffBracket(playoffTeamsA, playoffTeamsB)
    SeasonManager.currentPhase = SeasonManager.PHASE.PREPARATION
end

--- Advances the playoff bracket to next round
function SeasonManager.advancePlayoffs()
    local currentRound = SeasonManager.playoffBracket.currentRound

    if currentRound == "wildcard" then
        SeasonManager.playoffBracket.currentRound = "divisional"
        SeasonManager.currentWeek = 19
    elseif currentRound == "divisional" then
        SeasonManager.playoffBracket.currentRound = "conference"
        SeasonManager.currentWeek = 20
    elseif currentRound == "conference" then
        SeasonManager.playoffBracket.currentRound = "championship"
        SeasonManager.currentWeek = 21
    else
        -- Championship complete - season over
        SeasonManager.currentPhase = "season_end"
        return
    end

    SeasonManager.currentPhase = SeasonManager.PHASE.PREPARATION
end

--- Gets the player's playoff match for the current round
--- @return table|nil Match data or nil if eliminated
function SeasonManager.getPlayerPlayoffMatch()
    if not SeasonManager.inPlayoffs then
        return nil
    end

    local currentRound = SeasonManager.playoffBracket.currentRound
    local matches = SeasonManager.playoffBracket[currentRound]

    if not matches then
        return nil
    end

    -- Find player's match
    for _, match in ipairs(matches) do
        if match.homeTeam == SeasonManager.playerTeam or match.awayTeam == SeasonManager.playerTeam then
            local opponent = (match.homeTeam == SeasonManager.playerTeam) and match.awayTeam or match.homeTeam
            return {
                playerTeam = SeasonManager.playerTeam,
                opponentTeam = opponent,
                weekNumber = SeasonManager.currentWeek,
                isHome = (match.homeTeam == SeasonManager.playerTeam),
                round = currentRound
            }
        end
    end

    -- Player not in current round - eliminated
    SeasonManager.currentPhase = "season_end"
    return nil
end

--- Checks if the season has ended
--- @return boolean True if season complete
function SeasonManager.isSeasonComplete()
    return SeasonManager.currentPhase == "season_end"
end

--- Gets the full regular season schedule
--- @return table Array of 17 weeks, each with array of matches
function SeasonManager.getFullSchedule()
    return SeasonManager.schedule
end

--- Gets current standings for a conference
--- @param conference string "A" or "B"
--- @return table Sorted array of teams
function SeasonManager.getStandings(conference)
    local conferenceTeams = Team.getTeamsInConference(SeasonManager.teams, conference)
    return Team.sortByStandings(conferenceTeams)
end

return SeasonManager
