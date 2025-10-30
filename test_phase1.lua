--- test_phase1.lua
--- Test Suite for Phase 1 Data Structures
---
--- Tests team.lua, season_manager.lua, schedule_generator.lua, and card.lua updates
--- Run with: love . --test

local Team = require("team")
local Card = require("card")
local ScheduleGenerator = require("schedule_generator")

local testResults = {}
local testCount = 0
local passCount = 0

--- Helper function to run a test
local function test(name, func)
    testCount = testCount + 1
    local success, error = pcall(func)

    if success then
        passCount = passCount + 1
        table.insert(testResults, {name = name, passed = true})
        print(string.format("✓ PASS: %s", name))
    else
        table.insert(testResults, {name = name, passed = false, error = error})
        print(string.format("✗ FAIL: %s", name))
        print(string.format("  Error: %s", error))
    end
end

--- Helper function to assert
local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message or "Assertion failed", tostring(expected), tostring(actual)))
    end
end

local function assert_true(condition, message)
    if not condition then
        error(message or "Expected true, got false")
    end
end

--- Test Suite
print("\n========================================")
print("Phase 1 Data Structures Test Suite")
print("========================================\n")

-- Test 1: Team creation
test("Team creation with all fields", function()
    local team = Team:new("Test Team", "A", "offensive_guru", true)
    assert_equal(team.name, "Test Team", "Team name incorrect")
    assert_equal(team.conference, "A", "Conference incorrect")
    assert_equal(team.coachId, "offensive_guru", "Coach ID incorrect")
    assert_equal(team.isPlayer, true, "Player flag incorrect")
    assert_equal(team.wins, 0, "Wins should start at 0")
    assert_equal(team.losses, 0, "Losses should start at 0")
end)

-- Test 2: Team win recording
test("Team win recording updates stats", function()
    local team = Team:new("Winner", "A", "offensive_guru", false)
    team:recordWin(35, 14, "Loser Team")
    assert_equal(team.wins, 1, "Wins not incremented")
    assert_equal(team.pointsFor, 35, "Points for not recorded")
    assert_equal(team.pointsAgainst, 14, "Points against not recorded")
    assert_equal(team:getPointDifferential(), 21, "Point differential incorrect")
end)

-- Test 3: Team head-to-head tracking
test("Team head-to-head result tracking", function()
    local teamA = Team:new("Team A", "A", "offensive_guru", false)
    local teamB = Team:new("Team B", "A", "defensive_genius", false)

    teamA:recordWin(21, 17, "Team B")
    teamB:recordLoss(17, 21, "Team A")

    assert_equal(teamA:beatTeam("Team B"), true, "Team A should have beaten Team B")
    assert_equal(teamB:beatTeam("Team A"), false, "Team B should have lost to Team A")
end)

-- Test 4: Team standings sort
test("Team standings sorting by tiebreakers", function()
    local team1 = Team:new("Team 1", "A", "offensive_guru", false)
    local team2 = Team:new("Team 2", "A", "defensive_genius", false)
    local team3 = Team:new("Team 3", "A", "balanced", false)

    -- Team 1: 10-7, +50 point diff
    team1.wins = 10
    team1.losses = 7
    team1.pointsFor = 350
    team1.pointsAgainst = 300

    -- Team 2: 10-7, +30 point diff
    team2.wins = 10
    team2.losses = 7
    team2.pointsFor = 330
    team2.pointsAgainst = 300

    -- Team 3: 11-6
    team3.wins = 11
    team3.losses = 6
    team3.pointsFor = 320
    team3.pointsAgainst = 300

    local sorted = Team.sortByStandings({team1, team2, team3})

    assert_equal(sorted[1].name, "Team 3", "Best record should be first")
    assert_equal(sorted[2].name, "Team 1", "Better point diff should be second")
    assert_equal(sorted[3].name, "Team 2", "Worst point diff should be third")
end)

-- Test 5: Card number generation
test("Card number generation is position-realistic", function()
    local qbNum = Card.generateNumber("QB")
    assert_true(qbNum >= 1 and qbNum <= 19, "QB number out of range")

    local rbNum = Card.generateNumber("RB")
    assert_true(rbNum >= 20 and rbNum <= 49, "RB number out of range")

    local olNum = Card.generateNumber("OL")
    assert_true(olNum >= 50 and olNum <= 79, "OL number out of range")
end)

-- Test 6: Card upgrade system
test("Card yards upgrade increases yards", function()
    local card = Card:new("QB", Card.TYPE.YARD_GENERATOR, {
        yardsPerAction = 5.0,
        speed = 3.6
    })

    assert_equal(card.yardsPerAction, 5.0, "Initial yards incorrect")
    assert_equal(card.upgradeCount, 0, "Upgrade count should start at 0")
    assert_true(card:canUpgrade(), "Card should be upgradeable")

    local success = card:upgradeYards()
    assert_true(success, "Yards upgrade should succeed")
    assert_equal(card.yardsPerAction, 5.5, "Yards not upgraded correctly")
    assert_equal(card.upgradeCount, 1, "Upgrade count not incremented")
end)

-- Test 7: Card cooldown upgrade
test("Card cooldown upgrade reduces cooldown", function()
    local card = Card:new("RB", Card.TYPE.YARD_GENERATOR, {
        yardsPerAction = 3.0,
        speed = 4.0
    })

    assert_equal(card.cooldown, 4.0, "Initial cooldown incorrect")

    local success = card:upgradeCooldown()
    assert_true(success, "Cooldown upgrade should succeed")
    assert_true(card.cooldown < 4.0, "Cooldown should be reduced")
    assert_true(math.abs(card.cooldown - 3.6) < 0.01, "Cooldown should be 3.6 (90% of 4.0)")
end)

-- Test 8: Card upgrade limit
test("Card upgrade limit enforced at 3", function()
    local card = Card:new("WR", Card.TYPE.YARD_GENERATOR, {
        yardsPerAction = 4.0,
        speed = 3.0
    })

    assert_true(card:upgradeYards(), "First upgrade should succeed")
    assert_true(card:upgradeYards(), "Second upgrade should succeed")
    assert_true(card:upgradeCooldown(), "Third upgrade should succeed")
    assert_equal(card.upgradeCount, 3, "Should have 3 upgrades")
    assert_true(not card:canUpgrade(), "Card should not be upgradeable anymore")

    local fourthUpgrade = card:upgradeYards()
    assert_true(not fourthUpgrade, "Fourth upgrade should fail")
end)

-- Test 9: League generation
test("League generation creates 18 teams", function()
    local teams = Team.generateLeague()
    assert_equal(#teams, 18, "Should generate exactly 18 teams")

    local confA = Team.getTeamsInConference(teams, "A")
    local confB = Team.getTeamsInConference(teams, "B")

    assert_equal(#confA, 9, "Conference A should have 9 teams")
    assert_equal(#confB, 9, "Conference B should have 9 teams")
end)

-- Test 10: Round-robin schedule generation
test("Round-robin schedule generation creates valid schedule", function()
    local teams = Team.generateLeague()
    local schedule = ScheduleGenerator.generateRegularSeason(teams)

    assert_equal(#schedule, 17, "Should generate 17 weeks")

    -- Check week 1 has 9 matches
    assert_equal(#schedule[1], 9, "Week 1 should have 9 matches")

    -- Verify each team appears exactly once per week
    for week, matches in ipairs(schedule) do
        local teamsThisWeek = {}
        for _, match in ipairs(matches) do
            teamsThisWeek[match.homeTeam.name] = true
            teamsThisWeek[match.awayTeam.name] = true
        end

        local count = 0
        for _ in pairs(teamsThisWeek) do
            count = count + 1
        end

        assert_equal(count, 18, string.format("Week %d should have all 18 teams", week))
    end
end)

-- Test 11: Playoff bracket structure
test("Playoff bracket generates correctly", function()
    local teams = Team.generateLeague()
    local confA = Team.getTeamsInConference(teams, "A")
    local confB = Team.getTeamsInConference(teams, "B")

    -- Sort to get top 6
    local standingsA = Team.sortByStandings(confA)
    local standingsB = Team.sortByStandings(confB)

    local playoffTeamsA = {standingsA[1], standingsA[2], standingsA[3], standingsA[4], standingsA[5], standingsA[6]}
    local playoffTeamsB = {standingsB[1], standingsB[2], standingsB[3], standingsB[4], standingsB[5], standingsB[6]}

    local bracket = ScheduleGenerator.generatePlayoffBracket(playoffTeamsA, playoffTeamsB)

    assert_equal(bracket.currentRound, "wildcard", "Should start at Wild Card round")
    assert_equal(#bracket.wildcard, 4, "Wild Card should have 4 matches (2 per conference)")
end)

-- Test 12: Cash management
test("Team cash management for player team", function()
    local team = Team:new("Player Team", "A", "offensive_guru", true)

    team:awardCash(150)
    assert_equal(team.cash, 150, "Cash not awarded correctly")

    local success = team:spendCash(50)
    assert_true(success, "Should be able to spend 50 cash")
    assert_equal(team.cash, 100, "Cash not deducted correctly")

    local failSpend = team:spendCash(200)
    assert_true(not failSpend, "Should not be able to spend more than available")
end)

-- Print summary
print("\n========================================")
print("Test Summary")
print("========================================")
print(string.format("Total Tests: %d", testCount))
print(string.format("Passed: %d", passCount))
print(string.format("Failed: %d", testCount - passCount))
print(string.format("Success Rate: %.1f%%", (passCount / testCount) * 100))
print("========================================\n")

if passCount == testCount then
    print("✓ All tests passed! Phase 1 data structures are working correctly.\n")
    return true
else
    print("✗ Some tests failed. Please review the errors above.\n")
    return false
end
