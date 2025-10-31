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
ScheduleScreen.showBracket = false  -- Toggle between schedule and bracket view

-- UI configuration
local GAME_ROW_HEIGHT = 45
local GAME_WIDTH = 700
local START_X = 50
local START_Y = 20
local TOGGLE_BUTTON_X = 900
local TOGGLE_BUTTON_Y = 20
local TOGGLE_BUTTON_WIDTH = 200
local TOGGLE_BUTTON_HEIGHT = 40

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

    -- Draw toggle button if in playoffs (not scrolling)
    if SeasonManager.inPlayoffs then
        local mx, my = love.mouse.getPosition()
        my = my - 100  -- Adjust for header
        local hovering = mx >= TOGGLE_BUTTON_X and mx <= TOGGLE_BUTTON_X + TOGGLE_BUTTON_WIDTH and
                        my >= TOGGLE_BUTTON_Y and my <= TOGGLE_BUTTON_Y + TOGGLE_BUTTON_HEIGHT

        if hovering then
            love.graphics.setColor(0.3, 0.3, 0.4)
        else
            love.graphics.setColor(0.2, 0.2, 0.25)
        end
        love.graphics.rectangle("fill", TOGGLE_BUTTON_X, TOGGLE_BUTTON_Y, TOGGLE_BUTTON_WIDTH, TOGGLE_BUTTON_HEIGHT)

        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", TOGGLE_BUTTON_X, TOGGLE_BUTTON_Y, TOGGLE_BUTTON_WIDTH, TOGGLE_BUTTON_HEIGHT)

        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.setColor(1, 1, 1)
        local buttonText = ScheduleScreen.showBracket and "Show Schedule" or "Show Bracket"
        local textWidth = love.graphics.getFont():getWidth(buttonText)
        love.graphics.print(buttonText, TOGGLE_BUTTON_X + (TOGGLE_BUTTON_WIDTH - textWidth) / 2, TOGGLE_BUTTON_Y + 10)
    end

    love.graphics.push()
    love.graphics.translate(0, -ScheduleScreen.scrollOffset)

    local yOffset = START_Y

    -- Title
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.setColor(1, 1, 1)
    local title = ScheduleScreen.showBracket and "Playoff Bracket" or "Season Schedule"
    love.graphics.print(title, START_X, yOffset)
    yOffset = yOffset + 50

    -- Draw bracket or schedule based on toggle
    if ScheduleScreen.showBracket and SeasonManager.inPlayoffs then
        ScheduleScreen.drawBracket(yOffset)
    else
        ScheduleScreen.drawSchedule(yOffset)
    end

    love.graphics.pop()
end

--- Draws the regular schedule view
--- @param yOffset number Starting Y position
function ScheduleScreen.drawSchedule(yOffset)
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

    -- Playoff games (only shown in schedule view)
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

--- Draws the playoff bracket in a tree format
--- @param yOffset number Starting Y position
function ScheduleScreen.drawBracket(yOffset)
    if not SeasonManager.playoffBracket then
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.print("Playoffs have not started yet", START_X, yOffset)
        return
    end

    local bracket = SeasonManager.playoffBracket
    local MATCHUP_WIDTH = 200
    local MATCHUP_HEIGHT = 70
    local ROUND_SPACING = 250
    local MATCHUP_SPACING = 100

    -- Conference A bracket (top)
    local confAStartY = yOffset
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.print("Conference A", START_X, confAStartY)
    confAStartY = confAStartY + 35

    -- Conference B bracket (bottom)
    local confBStartY = confAStartY + 400
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.print("Conference B", START_X, confBStartY)
    confBStartY = confBStartY + 35

    -- Draw Wild Card round (if exists)
    if bracket.wildcard and #bracket.wildcard > 0 then
        local x = START_X
        local confAWildcard = {}
        local confBWildcard = {}

        -- Separate by conference
        for _, match in ipairs(bracket.wildcard) do
            if match.homeTeam.conference == "A" then
                table.insert(confAWildcard, match)
            else
                table.insert(confBWildcard, match)
            end
        end

        -- Draw Conference A wildcard games
        for i, match in ipairs(confAWildcard) do
            local y = confAStartY + ((i - 1) * (MATCHUP_HEIGHT + MATCHUP_SPACING))
            ScheduleScreen.drawBracketMatch(match, x, y, "wildcard")
        end

        -- Draw Conference B wildcard games
        for i, match in ipairs(confBWildcard) do
            local y = confBStartY + ((i - 1) * (MATCHUP_HEIGHT + MATCHUP_SPACING))
            ScheduleScreen.drawBracketMatch(match, x, y, "wildcard")
        end
    end

    -- Draw Divisional round
    if bracket.divisional and #bracket.divisional > 0 then
        local x = START_X + ROUND_SPACING
        local confADiv = {}
        local confBDiv = {}

        for _, match in ipairs(bracket.divisional) do
            if match.homeTeam.conference == "A" then
                table.insert(confADiv, match)
            else
                table.insert(confBDiv, match)
            end
        end

        for i, match in ipairs(confADiv) do
            local y = confAStartY + 50 + ((i - 1) * (MATCHUP_HEIGHT + MATCHUP_SPACING * 2))
            ScheduleScreen.drawBracketMatch(match, x, y, "divisional")
        end

        for i, match in ipairs(confBDiv) do
            local y = confBStartY + 50 + ((i - 1) * (MATCHUP_HEIGHT + MATCHUP_SPACING * 2))
            ScheduleScreen.drawBracketMatch(match, x, y, "divisional")
        end
    end

    -- Draw Conference Championship
    if bracket.conference and #bracket.conference > 0 then
        local x = START_X + (ROUND_SPACING * 2)

        for i, match in ipairs(bracket.conference) do
            local y
            if match.homeTeam.conference == "A" then
                y = confAStartY + 150
            else
                y = confBStartY + 150
            end
            ScheduleScreen.drawBracketMatch(match, x, y, "conference")
        end
    end

    -- Draw Championship (center)
    if bracket.championship and #bracket.championship > 0 then
        local x = START_X + (ROUND_SPACING * 3)
        local y = (confAStartY + confBStartY) / 2 + 50
        ScheduleScreen.drawBracketMatch(bracket.championship[1], x, y, "championship")
    end
end

--- Draws a single bracket matchup
--- @param match table The match data
--- @param x number X position
--- @param y number Y position
--- @param round string Current round name
function ScheduleScreen.drawBracketMatch(match, x, y, round)
    local MATCHUP_WIDTH = 200
    local MATCHUP_HEIGHT = 70
    local hasPlayed = match.played
    local isFutureRound = false

    -- Determine if this is a future round
    if round == "wildcard" and SeasonManager.playoffBracket.currentRound == "wildcard" then
        isFutureRound = false
    elseif round == "divisional" and (SeasonManager.playoffBracket.currentRound == "wildcard") then
        isFutureRound = true
    elseif round == "conference" and (SeasonManager.playoffBracket.currentRound == "wildcard" or SeasonManager.playoffBracket.currentRound == "divisional") then
        isFutureRound = true
    elseif round == "championship" and SeasonManager.playoffBracket.currentRound ~= "championship" then
        isFutureRound = true
    end

    -- Background
    if isFutureRound then
        love.graphics.setColor(0.15, 0.15, 0.18, 0.5)  -- Grayed out
    elseif hasPlayed then
        love.graphics.setColor(0.2, 0.25, 0.28)
    else
        love.graphics.setColor(0.2, 0.2, 0.25)
    end
    love.graphics.rectangle("fill", x, y, MATCHUP_WIDTH, MATCHUP_HEIGHT)

    -- Border
    if hasPlayed and not isFutureRound then
        love.graphics.setColor(0.8, 0.8, 0.3)
        love.graphics.setLineWidth(3)
    else
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.setLineWidth(2)
    end
    love.graphics.rectangle("line", x, y, MATCHUP_WIDTH, MATCHUP_HEIGHT)

    -- Team names and scores
    love.graphics.setFont(love.graphics.newFont(16))

    -- Home team
    if isFutureRound then
        love.graphics.setColor(0.4, 0.4, 0.45)
    else
        love.graphics.setColor(0.9, 0.9, 1)
    end

    local homeText = match.homeTeam.name
    if string.len(homeText) > 18 then
        homeText = string.sub(homeText, 1, 15) .. "..."
    end
    love.graphics.print(homeText, x + 10, y + 10)

    if hasPlayed then
        love.graphics.print(tostring(match.homeScore), x + MATCHUP_WIDTH - 30, y + 10)
    end

    -- Away team
    local awayText = match.awayTeam.name
    if string.len(awayText) > 18 then
        awayText = string.sub(awayText, 1, 15) .. "..."
    end
    love.graphics.print(awayText, x + 10, y + 40)

    if hasPlayed then
        love.graphics.print(tostring(match.awayScore), x + MATCHUP_WIDTH - 30, y + 40)
    end

    -- Winner indicator (bold line would be drawn separately as connections)
    if hasPlayed then
        local winner = match.homeScore > match.awayScore and match.homeTeam or match.awayTeam
        if winner then
            love.graphics.setColor(0.3, 0.8, 0.3)
            love.graphics.setLineWidth(2)
            if winner == match.homeTeam then
                love.graphics.rectangle("line", x + 5, y + 5, MATCHUP_WIDTH - 10, 25)
            else
                love.graphics.rectangle("line", x + 5, y + 35, MATCHUP_WIDTH - 10, 25)
            end
        end
    end
end

--- LÖVE Callback: Mouse Pressed
--- @param x number Mouse X position
--- @param y number Mouse Y position
--- @param button number Mouse button
function ScheduleScreen.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    -- Check toggle button click
    if SeasonManager.inPlayoffs then
        if x >= TOGGLE_BUTTON_X and x <= TOGGLE_BUTTON_X + TOGGLE_BUTTON_WIDTH and
           y >= TOGGLE_BUTTON_Y and y <= TOGGLE_BUTTON_Y + TOGGLE_BUTTON_HEIGHT then
            ScheduleScreen.showBracket = not ScheduleScreen.showBracket
        end
    end
end

--- Handles mouse wheel scrolling
--- @param y number Scroll amount
function ScheduleScreen.wheelmoved(y)
    ScheduleScreen.scrollOffset = ScheduleScreen.scrollOffset - (y * 30)
    ScheduleScreen.scrollOffset = math.max(0, math.min(ScheduleScreen.scrollOffset, ScheduleScreen.maxScroll))
end

return ScheduleScreen
