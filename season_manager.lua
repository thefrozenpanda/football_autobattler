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
    local Card = require("card")
    local coachData = Coach.getById(playerCoachId)
    playerTeam.offensiveCards = Coach.createCardSet(coachData.offensiveCards)
    playerTeam.defensiveCards = Coach.createCardSet(coachData.defensiveCards)
    playerTeam.benchCards = {}  -- Start with empty bench
    playerTeam.cash = 100  -- Starting cash for first week training

    -- Create special teams cards
    if coachData.kicker then
        playerTeam.kicker = Card:new(coachData.kicker.position, coachData.kicker.cardType, coachData.kicker.stats)
    end
    if coachData.punter then
        playerTeam.punter = Card:new(coachData.punter.position, coachData.punter.cardType, coachData.punter.stats)
    end

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

    -- Clear weekly upgrade options for new week
    SeasonManager.weeklyUpgradeOptions = nil

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
    -- Clear weekly upgrade options for next week
    SeasonManager.weeklyUpgradeOptions = nil
end

--- Advances to the match phase
function SeasonManager.goToMatch()
    SeasonManager.currentPhase = SeasonManager.PHASE.MATCH
end

--- Updates player team cards with stats from the match
--- Copies match statistics from match cards to team cards
--- @param offensiveCards table Array of offensive cards from match
--- @param defensiveCards table Array of defensive cards from match
function SeasonManager.updatePlayerCardStats(offensiveCards, defensiveCards)
    if not SeasonManager.playerTeam then
        return
    end

    -- Update offensive cards
    for i, matchCard in ipairs(offensiveCards) do
        if SeasonManager.playerTeam.offensiveCards[i] then
            local teamCard = SeasonManager.playerTeam.offensiveCards[i]
            -- Accumulate stats
            teamCard.yardsGained = (teamCard.yardsGained or 0) + matchCard.yardsGained
            teamCard.touchdownsScored = (teamCard.touchdownsScored or 0) + matchCard.touchdownsScored
            teamCard.cardsBoosted = (teamCard.cardsBoosted or 0) + matchCard.cardsBoosted
        end
    end

    -- Update defensive cards
    for i, matchCard in ipairs(defensiveCards) do
        if SeasonManager.playerTeam.defensiveCards[i] then
            local teamCard = SeasonManager.playerTeam.defensiveCards[i]
            -- Accumulate stats
            teamCard.timesSlowed = (teamCard.timesSlowed or 0) + matchCard.timesSlowed
            teamCard.timesFroze = (teamCard.timesFroze or 0) + matchCard.timesFroze
            teamCard.yardsReduced = (teamCard.yardsReduced or 0) + matchCard.yardsReduced
        end
    end
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

    -- Update schedule to mark match as played and save scores
    if SeasonManager.schedule[SeasonManager.currentWeek] then
        for _, match in ipairs(SeasonManager.schedule[SeasonManager.currentWeek]) do
            if match.homeTeam == homeTeam and match.awayTeam == awayTeam then
                match.homeScore = homeScore
                match.awayScore = awayScore
                match.played = true
                break
            end
        end
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

            -- Award cash to AI teams (same as player: 100 for win, 50 for loss)
            if homeScore > awayScore then
                matchData.homeTeam:awardCash(100)  -- Winner
                matchData.awayTeam:awardCash(50)   -- Loser
            else
                matchData.awayTeam:awardCash(100)  -- Winner
                matchData.homeTeam:awardCash(50)   -- Loser
            end
        end
    end
end

--- Advances to the next week
--- If regular season complete, generates playoff bracket
function SeasonManager.nextWeek()
    SeasonManager.currentWeek = SeasonManager.currentWeek + 1

    -- Process AI training for the new week (before preparation phase)
    local AITraining = require("ai_training")
    for _, team in ipairs(SeasonManager.teams) do
        if not team.isPlayer then
            AITraining.processWeeklyUpgrades(team, SeasonManager.currentWeek)
        end
    end

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

--- Checks if player has a bye week in current playoff round
--- @return boolean True if player has bye week
function SeasonManager.playerHasByeWeek()
    if not SeasonManager.inPlayoffs or not SeasonManager.playoffBracket then
        return false
    end

    local currentRound = SeasonManager.playoffBracket.currentRound

    -- Only wildcard round has byes (for seeds 1-2)
    if currentRound ~= "wildcard" then
        return false
    end

    -- Check if player is in wildcard matches
    if SeasonManager.playoffBracket.wildcard then
        for _, match in ipairs(SeasonManager.playoffBracket.wildcard) do
            if match.homeTeam == SeasonManager.playerTeam or match.awayTeam == SeasonManager.playerTeam then
                return false  -- Player is playing in wildcard
            end
        end
    end

    -- Player made playoffs but not in wildcard = has bye week
    return true
end

--- Simulates all wildcard playoff games
function SeasonManager.simulateWildcardRound()
    if not SeasonManager.playoffBracket or not SeasonManager.playoffBracket.wildcard then
        return
    end

    local match = require("match")
    local ScheduleGenerator = require("schedule_generator")
    local results = {}

    -- Simulate all 4 wildcard games
    for _, matchData in ipairs(SeasonManager.playoffBracket.wildcard) do
        local homeScore, awayScore = match.simulateAIMatch(matchData.homeTeam, matchData.awayTeam)
        matchData.played = true
        matchData.homeScore = homeScore
        matchData.awayScore = awayScore

        -- Record result
        SeasonManager.recordMatchResult(matchData.homeTeam, matchData.awayTeam, homeScore, awayScore)

        -- Award cash to teams
        if homeScore > awayScore then
            matchData.homeTeam:awardCash(100)
            matchData.awayTeam:awardCash(50)
        else
            matchData.awayTeam:awardCash(100)
            matchData.homeTeam:awardCash(50)
        end

        table.insert(results, {
            homeTeam = matchData.homeTeam,
            awayTeam = matchData.awayTeam,
            homeScore = homeScore,
            awayScore = awayScore,
            conference = matchData.conference
        })
    end

    -- Advance bracket to divisional round
    ScheduleGenerator.advanceBracket(SeasonManager.playoffBracket, results)
    SeasonManager.advancePlayoffs()
end

--- Simulates all remaining playoff games after player elimination
--- Used when player loses in playoffs to complete the bracket
function SeasonManager.simulateRemainingPlayoffs()
    if not SeasonManager.inPlayoffs or not SeasonManager.playoffBracket then
        return
    end

    local match = require("match")
    local ScheduleGenerator = require("schedule_generator")
    local currentRound = SeasonManager.playoffBracket.currentRound

    -- Simulate remaining matches in current round
    local function simulateRound(roundName)
        local matches = SeasonManager.playoffBracket[roundName]
        if not matches then return false end

        local results = {}
        for _, matchData in ipairs(matches) do
            if not matchData.played then
                local homeScore, awayScore = match.simulateAIMatch(matchData.homeTeam, matchData.awayTeam)
                matchData.played = true
                matchData.homeScore = homeScore
                matchData.awayScore = awayScore

                -- Determine winner
                local winner = (homeScore > awayScore) and matchData.homeTeam or matchData.awayTeam
                table.insert(results, {
                    winner = winner,
                    homeTeam = matchData.homeTeam,
                    awayTeam = matchData.awayTeam,
                    conference = matchData.conference
                })
            end
        end

        -- Advance bracket if matches were played
        if #results > 0 then
            ScheduleGenerator.advanceBracket(SeasonManager.playoffBracket, results)
            return true
        end

        return false
    end

    -- Simulate current round if needed
    if simulateRound(currentRound) then
        -- Advance to next round
        if currentRound == "wildcard" then
            SeasonManager.playoffBracket.currentRound = "divisional"
            currentRound = "divisional"
        elseif currentRound == "divisional" then
            SeasonManager.playoffBracket.currentRound = "conference"
            currentRound = "conference"
        elseif currentRound == "conference" then
            SeasonManager.playoffBracket.currentRound = "championship"
            currentRound = "championship"
        else
            -- Done
            SeasonManager.currentPhase = "season_end"
            return
        end
    end

    -- Simulate remaining rounds
    local roundOrder = {"divisional", "conference", "championship"}
    local startSimulating = false

    for _, roundName in ipairs(roundOrder) do
        if roundName == currentRound then
            startSimulating = true
        end

        if startSimulating then
            simulateRound(roundName)
            -- Update bracket's current round
            SeasonManager.playoffBracket.currentRound = roundName
        end
    end

    -- Mark season as complete
    SeasonManager.currentPhase = "season_end"
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

--- Saves the current season state to a file
--- @return boolean True if save successful
function SeasonManager.saveSeason()
    local saveData = {
        version = "1.0",
        currentWeek = SeasonManager.currentWeek,
        currentPhase = SeasonManager.currentPhase,
        inPlayoffs = SeasonManager.inPlayoffs,
        teams = {},
        schedule = {},
        playoffBracket = {}
    }

    -- Save all teams
    for _, team in ipairs(SeasonManager.teams) do
        local teamData = {
            name = team.name,
            conference = team.conference,
            coachId = team.coachId,
            isPlayer = team.isPlayer,
            wins = team.wins,
            losses = team.losses,
            pointsFor = team.pointsFor,
            pointsAgainst = team.pointsAgainst,
            cash = team.cash,
            eliminated = team.eliminated
        }

        -- Save cards with upgrades and match statistics
        teamData.offensiveCards = {}
        for _, card in ipairs(team.offensiveCards) do
            table.insert(teamData.offensiveCards, {
                position = card.position,
                number = card.number,
                cardType = card.cardType,
                -- Base stats
                baseYardsPerAction = card.baseYardsPerAction,
                baseCooldown = card.baseCooldown,
                -- Current stats
                yardsPerAction = card.yardsPerAction,
                cooldown = card.cooldown,
                boostAmount = card.boostAmount,
                boostTargets = card.boostTargets,
                effectType = card.effectType,
                effectStrength = card.effectStrength,
                targetPositions = card.targetPositions,
                -- Upgrade tracking
                upgradeCount = card.upgradeCount,
                yardsUpgrades = card.yardsUpgrades,
                cooldownUpgrades = card.cooldownUpgrades,
                boostUpgrades = card.boostUpgrades or 0,
                durationUpgrades = card.durationUpgrades or 0,
                bonusYardsUpgrades = card.bonusYardsUpgrades or 0,
                hasImmunity = card.hasImmunity or false,
                -- Match statistics
                yardsGained = card.yardsGained or 0,
                touchdownsScored = card.touchdownsScored or 0,
                cardsBoosted = card.cardsBoosted or 0
            })
        end

        teamData.defensiveCards = {}
        for _, card in ipairs(team.defensiveCards) do
            table.insert(teamData.defensiveCards, {
                position = card.position,
                number = card.number,
                cardType = card.cardType,
                -- Base stats
                baseYardsPerAction = card.baseYardsPerAction,
                baseCooldown = card.baseCooldown,
                -- Current stats
                yardsPerAction = card.yardsPerAction,
                cooldown = card.cooldown,
                boostAmount = card.boostAmount,
                boostTargets = card.boostTargets,
                effectType = card.effectType,
                effectStrength = card.effectStrength,
                targetPositions = card.targetPositions,
                -- Upgrade tracking
                upgradeCount = card.upgradeCount,
                yardsUpgrades = card.yardsUpgrades,
                cooldownUpgrades = card.cooldownUpgrades,
                boostUpgrades = card.boostUpgrades or 0,
                durationUpgrades = card.durationUpgrades or 0,
                bonusYardsUpgrades = card.bonusYardsUpgrades or 0,
                hasImmunity = card.hasImmunity or false,
                -- Match statistics
                timesSlowed = card.timesSlowed or 0,
                timesFroze = card.timesFroze or 0,
                yardsReduced = card.yardsReduced or 0
            })
        end

        teamData.benchCards = {}
        for _, card in ipairs(team.benchCards) do
            table.insert(teamData.benchCards, {
                position = card.position,
                number = card.number,
                cardType = card.cardType,
                -- Base stats
                baseYardsPerAction = card.baseYardsPerAction,
                baseCooldown = card.baseCooldown,
                -- Current stats
                yardsPerAction = card.yardsPerAction,
                cooldown = card.cooldown,
                boostAmount = card.boostAmount,
                boostTargets = card.boostTargets,
                effectType = card.effectType,
                effectStrength = card.effectStrength,
                targetPositions = card.targetPositions,
                -- Upgrade tracking
                upgradeCount = card.upgradeCount,
                yardsUpgrades = card.yardsUpgrades,
                cooldownUpgrades = card.cooldownUpgrades,
                boostUpgrades = card.boostUpgrades or 0,
                durationUpgrades = card.durationUpgrades or 0,
                bonusYardsUpgrades = card.bonusYardsUpgrades or 0,
                hasImmunity = card.hasImmunity or false,
                -- Match statistics (for all card types)
                yardsGained = card.yardsGained or 0,
                touchdownsScored = card.touchdownsScored or 0,
                cardsBoosted = card.cardsBoosted or 0,
                timesSlowed = card.timesSlowed or 0,
                timesFroze = card.timesFroze or 0,
                yardsReduced = card.yardsReduced or 0
            })
        end

        table.insert(saveData.teams, teamData)
    end

    -- Save schedule
    for week, matches in ipairs(SeasonManager.schedule) do
        saveData.schedule[week] = {}
        for _, match in ipairs(matches) do
            table.insert(saveData.schedule[week], {
                homeTeamName = match.homeTeam.name,
                awayTeamName = match.awayTeam.name,
                homeScore = match.homeScore,
                awayScore = match.awayScore,
                played = match.played
            })
        end
    end

    -- Save playoff bracket (if exists)
    if SeasonManager.playoffBracket and SeasonManager.playoffBracket.currentRound then
        saveData.playoffBracket.currentRound = SeasonManager.playoffBracket.currentRound

        -- Helper function to save a playoff match
        local function saveMatch(match)
            if match then
                return {
                    homeTeamName = match.homeTeam.name,
                    awayTeamName = match.awayTeam.name,
                    homeScore = match.homeScore,
                    awayScore = match.awayScore,
                    played = match.played
                }
            end
            return nil
        end

        -- Save each round
        if SeasonManager.playoffBracket.wildcard then
            saveData.playoffBracket.wildcard = {}
            for _, match in ipairs(SeasonManager.playoffBracket.wildcard) do
                table.insert(saveData.playoffBracket.wildcard, saveMatch(match))
            end
        end

        if SeasonManager.playoffBracket.divisional then
            saveData.playoffBracket.divisional = {}
            for _, match in ipairs(SeasonManager.playoffBracket.divisional) do
                table.insert(saveData.playoffBracket.divisional, saveMatch(match))
            end
        end

        if SeasonManager.playoffBracket.conference then
            saveData.playoffBracket.conference = {}
            for _, match in ipairs(SeasonManager.playoffBracket.conference) do
                table.insert(saveData.playoffBracket.conference, saveMatch(match))
            end
        end

        if SeasonManager.playoffBracket.championship then
            saveData.playoffBracket.championship = {}
            for _, match in ipairs(SeasonManager.playoffBracket.championship) do
                table.insert(saveData.playoffBracket.championship, saveMatch(match))
            end
        end
    end

    -- Serialize to string
    local serialized = SeasonManager.serializeTable(saveData)

    -- Write to file
    local success, message = love.filesystem.write("season_save.lua", serialized)
    return success
end

--- Loads season state from file
--- @return boolean True if load successful
function SeasonManager.loadSeason()
    if not love.filesystem.getInfo("season_save.lua") then
        return false
    end

    local contents, size = love.filesystem.read("season_save.lua")
    if not contents then
        return false
    end

    -- Deserialize
    local saveData = SeasonManager.deserializeTable(contents)
    if not saveData or saveData.version ~= "1.0" then
        return false
    end

    -- Restore state
    SeasonManager.currentWeek = saveData.currentWeek
    SeasonManager.currentPhase = saveData.currentPhase
    SeasonManager.inPlayoffs = saveData.inPlayoffs

    -- Restore teams
    SeasonManager.teams = {}
    local Card = require("card")

    for _, teamData in ipairs(saveData.teams) do
        local team = Team:new(teamData.name, teamData.conference, teamData.coachId, teamData.isPlayer)
        team.wins = teamData.wins
        team.losses = teamData.losses
        team.pointsFor = teamData.pointsFor
        team.pointsAgainst = teamData.pointsAgainst
        team.cash = teamData.cash
        team.eliminated = teamData.eliminated or false

        -- Restore cards
        team.offensiveCards = {}
        for _, cardData in ipairs(teamData.offensiveCards) do
            -- Create stats object from saved data
            local stats = {
                number = cardData.number,
                yardsPerAction = cardData.baseYardsPerAction or cardData.yardsPerAction or 0,
                speed = cardData.baseCooldown or cardData.cooldown or 1.5,
                boostAmount = cardData.boostAmount or 0,
                boostTargets = cardData.boostTargets or {},
                effectType = cardData.effectType,
                effectStrength = cardData.effectStrength or 0,
                targetPositions = cardData.targetPositions or {}
            }

            local card = Card:new(cardData.position, cardData.cardType, stats)

            -- Restore upgrade tracking
            card.upgradeCount = cardData.upgradeCount
            card.yardsUpgrades = cardData.yardsUpgrades
            card.cooldownUpgrades = cardData.cooldownUpgrades
            card.boostUpgrades = cardData.boostUpgrades or 0
            card.durationUpgrades = cardData.durationUpgrades or 0
            card.bonusYardsUpgrades = cardData.bonusYardsUpgrades or 0
            card.hasImmunity = cardData.hasImmunity or false

            -- Restore match statistics
            card.yardsGained = cardData.yardsGained or 0
            card.touchdownsScored = cardData.touchdownsScored or 0
            card.cardsBoosted = cardData.cardsBoosted or 0

            -- Apply upgrades to get current stats
            if cardData.upgradeCount and cardData.upgradeCount > 0 then
                card:recalculateStats()
            end

            table.insert(team.offensiveCards, card)
        end

        team.defensiveCards = {}
        for _, cardData in ipairs(teamData.defensiveCards) do
            -- Create stats object from saved data
            local stats = {
                number = cardData.number,
                yardsPerAction = cardData.baseYardsPerAction or cardData.yardsPerAction or 0,
                speed = cardData.baseCooldown or cardData.cooldown or 1.5,
                boostAmount = cardData.boostAmount or 0,
                boostTargets = cardData.boostTargets or {},
                effectType = cardData.effectType,
                effectStrength = cardData.effectStrength or 0,
                targetPositions = cardData.targetPositions or {}
            }

            local card = Card:new(cardData.position, cardData.cardType, stats)

            -- Restore upgrade tracking
            card.upgradeCount = cardData.upgradeCount
            card.yardsUpgrades = cardData.yardsUpgrades
            card.cooldownUpgrades = cardData.cooldownUpgrades
            card.boostUpgrades = cardData.boostUpgrades or 0
            card.durationUpgrades = cardData.durationUpgrades or 0
            card.bonusYardsUpgrades = cardData.bonusYardsUpgrades or 0
            card.hasImmunity = cardData.hasImmunity or false

            -- Restore match statistics
            card.timesSlowed = cardData.timesSlowed or 0
            card.timesFroze = cardData.timesFroze or 0
            card.yardsReduced = cardData.yardsReduced or 0

            -- Apply upgrades to get current stats
            if cardData.upgradeCount and cardData.upgradeCount > 0 then
                card:recalculateStats()
            end

            table.insert(team.defensiveCards, card)
        end

        team.benchCards = {}
        for _, cardData in ipairs(teamData.benchCards) do
            -- Create stats object from saved data
            local stats = {
                number = cardData.number,
                yardsPerAction = cardData.baseYardsPerAction or cardData.yardsPerAction or 0,
                speed = cardData.baseCooldown or cardData.cooldown or 1.5,
                boostAmount = cardData.boostAmount or 0,
                boostTargets = cardData.boostTargets or {},
                effectType = cardData.effectType,
                effectStrength = cardData.effectStrength or 0,
                targetPositions = cardData.targetPositions or {}
            }

            local card = Card:new(cardData.position, cardData.cardType, stats)

            -- Restore upgrade tracking
            card.upgradeCount = cardData.upgradeCount
            card.yardsUpgrades = cardData.yardsUpgrades
            card.cooldownUpgrades = cardData.cooldownUpgrades
            card.boostUpgrades = cardData.boostUpgrades or 0
            card.durationUpgrades = cardData.durationUpgrades or 0
            card.bonusYardsUpgrades = cardData.bonusYardsUpgrades or 0
            card.hasImmunity = cardData.hasImmunity or false

            -- Restore match statistics (for all card types)
            card.yardsGained = cardData.yardsGained or 0
            card.touchdownsScored = cardData.touchdownsScored or 0
            card.cardsBoosted = cardData.cardsBoosted or 0
            card.timesSlowed = cardData.timesSlowed or 0
            card.timesFroze = cardData.timesFroze or 0
            card.yardsReduced = cardData.yardsReduced or 0

            -- Apply upgrades to get current stats
            if cardData.upgradeCount and cardData.upgradeCount > 0 then
                card:recalculateStats()
            end

            table.insert(team.benchCards, card)
        end

        table.insert(SeasonManager.teams, team)

        if teamData.isPlayer then
            SeasonManager.playerTeam = team
        end
    end

    -- Restore schedule
    SeasonManager.schedule = {}
    for week, matchesData in ipairs(saveData.schedule) do
        SeasonManager.schedule[week] = {}
        for _, matchData in ipairs(matchesData) do
            -- Find teams by name
            local homeTeam = nil
            local awayTeam = nil
            for _, team in ipairs(SeasonManager.teams) do
                if team.name == matchData.homeTeamName then
                    homeTeam = team
                end
                if team.name == matchData.awayTeamName then
                    awayTeam = team
                end
            end

            table.insert(SeasonManager.schedule[week], {
                homeTeam = homeTeam,
                awayTeam = awayTeam,
                homeScore = matchData.homeScore,
                awayScore = matchData.awayScore,
                played = matchData.played
            })
        end
    end

    -- Restore playoff bracket
    if saveData.playoffBracket and saveData.playoffBracket.currentRound then
        SeasonManager.playoffBracket = {currentRound = saveData.playoffBracket.currentRound}

        local function loadMatch(matchData)
            if matchData then
                local homeTeam = nil
                local awayTeam = nil
                for _, team in ipairs(SeasonManager.teams) do
                    if team.name == matchData.homeTeamName then
                        homeTeam = team
                    end
                    if team.name == matchData.awayTeamName then
                        awayTeam = team
                    end
                end

                return {
                    homeTeam = homeTeam,
                    awayTeam = awayTeam,
                    homeScore = matchData.homeScore,
                    awayScore = matchData.awayScore,
                    played = matchData.played
                }
            end
            return nil
        end

        if saveData.playoffBracket.wildcard then
            SeasonManager.playoffBracket.wildcard = {}
            for _, matchData in ipairs(saveData.playoffBracket.wildcard) do
                table.insert(SeasonManager.playoffBracket.wildcard, loadMatch(matchData))
            end
        end

        if saveData.playoffBracket.divisional then
            SeasonManager.playoffBracket.divisional = {}
            for _, matchData in ipairs(saveData.playoffBracket.divisional) do
                table.insert(SeasonManager.playoffBracket.divisional, loadMatch(matchData))
            end
        end

        if saveData.playoffBracket.conference then
            SeasonManager.playoffBracket.conference = {}
            for _, matchData in ipairs(saveData.playoffBracket.conference) do
                table.insert(SeasonManager.playoffBracket.conference, loadMatch(matchData))
            end
        end

        if saveData.playoffBracket.championship then
            SeasonManager.playoffBracket.championship = {}
            for _, matchData in ipairs(saveData.playoffBracket.championship) do
                table.insert(SeasonManager.playoffBracket.championship, loadMatch(matchData))
            end
        end
    end

    return true
end

--- Checks if a save file exists
--- @return boolean True if save exists
function SeasonManager.saveExists()
    return love.filesystem.getInfo("season_save.lua") ~= nil
end

--- Gets basic save info without fully loading the save
--- @return table|nil Save info with teamName, wins, losses, week, or nil if no save
function SeasonManager.getSaveInfo()
    if not SeasonManager.saveExists() then
        return nil
    end

    local saveStr = love.filesystem.read("season_save.lua")
    if not saveStr then
        return nil
    end

    -- Parse the save file to extract basic info
    local saveData = SeasonManager.deserializeTable(saveStr)
    if not saveData or not saveData.teams then
        return nil
    end

    -- Find the player team
    for _, teamData in ipairs(saveData.teams) do
        if teamData.isPlayer then
            return {
                teamName = teamData.name,
                wins = teamData.wins,
                losses = teamData.losses,
                week = saveData.currentWeek or 1
            }
        end
    end

    return nil
end

--- Deletes the save file
--- @return boolean True if deletion successful
function SeasonManager.deleteSave()
    return love.filesystem.remove("season_save.lua")
end

--- Simple table serializer
--- @param t table The table to serialize
--- @param indent string Current indentation
--- @return string Serialized table as Lua code
function SeasonManager.serializeTable(t, indent)
    indent = indent or ""
    local result = "{\n"

    for k, v in pairs(t) do
        result = result .. indent .. "  "

        -- Key
        if type(k) == "string" then
            result = result .. "[\"" .. k .. "\"] = "
        else
            result = result .. "[" .. tostring(k) .. "] = "
        end

        -- Value
        if type(v) == "table" then
            result = result .. SeasonManager.serializeTable(v, indent .. "  ")
        elseif type(v) == "string" then
            result = result .. "\"" .. v .. "\""
        elseif type(v) == "boolean" then
            result = result .. tostring(v)
        elseif type(v) == "number" then
            result = result .. tostring(v)
        else
            result = result .. "nil"
        end

        result = result .. ",\n"
    end

    result = result .. indent .. "}"
    return result
end

--- Simple table deserializer
--- @param str string Serialized table string
--- @return table Deserialized table
function SeasonManager.deserializeTable(str)
    local chunk = loadstring("return " .. str)
    if chunk then
        return chunk()
    end
    return nil
end

return SeasonManager
