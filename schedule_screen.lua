--- schedule_screen.lua
--- Schedule Screen
---
--- Displays the full season schedule including regular season (17 weeks)
--- and playoff games. Shows results for completed games.
---
--- Dependencies: season_manager.lua
--- Used by: season_menu.lua
--- LÖVE Callbacks: love.update, love.draw

local ScheduleScreen = {}

local SeasonManager = require("season_manager")

-- State
ScheduleScreen.scrollOffset = 0
ScheduleScreen.maxScroll = 0
ScheduleScreen.contentHeight = 700

-- UI configuration
local GAME_ROW_HEIGHT = 45
local GAME_WIDTH = 700
local START_X = 50
local START_Y = 20

--- Initializes the schedule screen
function ScheduleScreen.load()
    ScheduleScreen.scrollOffset = 0
    ScheduleScreen.calculateMaxScroll()
end

--- Calculates the maximum scroll amount
function ScheduleScreen.calculateMaxScroll()
    local totalGames = 17  -- Regular season

    if SeasonManager.inPlayoffs then
        -- Add playoff games
        if SeasonManager.playoffBracket.wildcard then
            totalGames = totalGames + 4  -- 4 Wild Card games
        end
        if SeasonManager.playoffBracket.currentRound == "divisional" or
           SeasonManager.playoffBracket.currentRound == "conference" or
           SeasonManager.playoffBracket.currentRound == "championship" then
            totalGames = totalGames + 4  -- 4 Divisional games
        end
        if SeasonManager.playoffBracket.currentRound == "conference" or
           SeasonManager.playoffBracket.currentRound == "championship" then
            totalGames = totalGames + 2  -- 2 Conference games
        end
        if SeasonManager.playoffBracket.currentRound == "championship" then
            totalGames = totalGames + 1  -- 1 Championship game
        end
    end

    local contentHeight = totalGames * GAME_ROW_HEIGHT
    ScheduleScreen.maxScroll = math.max(0, contentHeight - ScheduleScreen.contentHeight)
end

--- LÖVE Callback: Update Logic
--- @param dt number Delta time in seconds
function ScheduleScreen.update(dt)
    -- Handle scrolling with mouse wheel
    -- (Will be handled by love.wheelmoved in main.lua)
end

--- LÖVE Callback: Draw UI
function ScheduleScreen.draw()
    if not SeasonManager.playerTeam or not SeasonManager.schedule then
        return
    end

    love.graphics.push()
    love.graphics.translate(0, -ScheduleScreen.scrollOffset)

    local yOffset = START_Y

    -- Title
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Season Schedule", START_X, yOffset)
    yOffset = yOffset + 50

    -- Regular season games (17 weeks)
    for week = 1, 17 do
        local weekSchedule = SeasonManager.schedule[week]

        if weekSchedule then
            -- Find player's match
            local playerMatch = nil
            for _, match in ipairs(weekSchedule) do
                if match.homeTeam == SeasonManager.playerTeam or match.awayTeam == SeasonManager.playerTeam then
                    playerMatch = match
                    break
                end
            end

            if playerMatch then
                yOffset = ScheduleScreen.drawGameRow(playerMatch, week, yOffset, false)
            end
        end
    end

    -- Playoff games
    if SeasonManager.inPlayoffs and SeasonManager.playoffBracket then
        yOffset = yOffset + 30

        -- Section header
        love.graphics.setFont(love.graphics.newFont(28))
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.print("PLAYOFFS", START_X, yOffset)
        yOffset = yOffset + 40

        -- Wild Card
        if SeasonManager.playoffBracket.wildcard then
            for _, match in ipairs(SeasonManager.playoffBracket.wildcard) do
                if match.homeTeam == SeasonManager.playerTeam or match.awayTeam == SeasonManager.playerTeam then
                    yOffset = ScheduleScreen.drawGameRow(match, 18, yOffset, true, "Wild Card")
                end
            end
        end

        -- Divisional
        if SeasonManager.playoffBracket.divisional and #SeasonManager.playoffBracket.divisional > 0 then
            for _, match in ipairs(SeasonManager.playoffBracket.divisional) do
                if match.homeTeam == SeasonManager.playerTeam or match.awayTeam == SeasonManager.playerTeam then
                    yOffset = ScheduleScreen.drawGameRow(match, 19, yOffset, true, "Divisional")
                end
            end
        end

        -- Conference
        if SeasonManager.playoffBracket.conference and #SeasonManager.playoffBracket.conference > 0 then
            for _, match in ipairs(SeasonManager.playoffBracket.conference) do
                if match.homeTeam == SeasonManager.playerTeam or match.awayTeam == SeasonManager.playerTeam then
                    yOffset = ScheduleScreen.drawGameRow(match, 20, yOffset, true, "Conference")
                end
            end
        end

        -- Championship
        if SeasonManager.playoffBracket.championship and #SeasonManager.playoffBracket.championship > 0 then
            for _, match in ipairs(SeasonManager.playoffBracket.championship) do
                if match.homeTeam == SeasonManager.playerTeam or match.awayTeam == SeasonManager.playerTeam then
                    yOffset = ScheduleScreen.drawGameRow(match, 21, yOffset, true, "Championship")
                end
            end
        end
    end

    love.graphics.pop()
end

--- Draws a single game row
--- @param match table The match data
--- @param week number Week number
--- @param y number Y position
--- @param isPlayoff boolean Whether this is a playoff game
--- @param playoffRound string|nil Playoff round name
--- @return number New Y position
function ScheduleScreen.drawGameRow(match, week, y, isPlayoff, playoffRound)
    local isPlayerHome = (match.homeTeam == SeasonManager.playerTeam)
    local opponent = isPlayerHome and match.awayTeam or match.homeTeam
    local hasPlayed = match.played or week < SeasonManager.currentWeek

    -- Background
    if hasPlayed then
        love.graphics.setColor(0.2, 0.2, 0.25)
    else
        love.graphics.setColor(0.15, 0.2, 0.25)
    end
    love.graphics.rectangle("fill", START_X, y, GAME_WIDTH, GAME_ROW_HEIGHT)

    -- Border
    if week == SeasonManager.currentWeek and not hasPlayed then
        love.graphics.setColor(0.8, 0.8, 0.3)  -- Highlight current week
        love.graphics.setLineWidth(3)
    else
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.setLineWidth(2)
    end
    love.graphics.rectangle("line", START_X, y, GAME_WIDTH, GAME_ROW_HEIGHT)

    -- Week label
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(0.7, 0.7, 0.8)

    local weekText = ""
    if isPlayoff then
        weekText = playoffRound or string.format("Week %d", week)
    else
        weekText = string.format("Week %d", week)
    end
    love.graphics.print(weekText, START_X + 15, y + 12)

    -- Matchup
    love.graphics.setFont(love.graphics.newFont(22))
    love.graphics.setColor(1, 1, 1)

    local matchupText = ""
    if isPlayerHome then
        matchupText = string.format("%s vs %s", SeasonManager.playerTeam.name, opponent.name)
    else
        matchupText = string.format("%s @ %s", SeasonManager.playerTeam.name, opponent.name)
    end

    love.graphics.print(matchupText, START_X + 150, y + 10)

    -- Result
    if hasPlayed then
        local playerScore = isPlayerHome and match.homeScore or match.awayScore
        local opponentScore = isPlayerHome and match.awayScore or match.homeScore
        local playerWon = playerScore > opponentScore

        love.graphics.setFont(love.graphics.newFont(24))

        if playerWon then
            love.graphics.setColor(0.3, 0.8, 0.3)
            love.graphics.print(string.format("W %d-%d", playerScore, opponentScore), START_X + GAME_WIDTH - 120, y + 8)
        else
            love.graphics.setColor(0.8, 0.3, 0.3)
            love.graphics.print(string.format("L %d-%d", playerScore, opponentScore), START_X + GAME_WIDTH - 120, y + 8)
        end
    else
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.setColor(0.6, 0.6, 0.7)
        love.graphics.print("Not played", START_X + GAME_WIDTH - 120, y + 12)
    end

    return y + GAME_ROW_HEIGHT
end

--- Handles mouse wheel scrolling
--- @param y number Scroll amount
function ScheduleScreen.wheelmoved(y)
    ScheduleScreen.scrollOffset = ScheduleScreen.scrollOffset - (y * 30)
    ScheduleScreen.scrollOffset = math.max(0, math.min(ScheduleScreen.scrollOffset, ScheduleScreen.maxScroll))
end

return ScheduleScreen
