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
local UIScale = require("ui_scale")

-- State
ScheduleScreen.scrollOffset = 0
ScheduleScreen.maxScroll = 0
ScheduleScreen.contentHeight = 700
ScheduleScreen.showBracket = false  -- Toggle between schedule and bracket view

-- UI configuration (base values for 1600x900)
local GAME_ROW_HEIGHT = 45
local GAME_WIDTH = 700
local START_X = 50
local START_Y = 20
local TOGGLE_BUTTON_X = 900
local TOGGLE_BUTTON_Y = 20
local TOGGLE_BUTTON_WIDTH = 200
local TOGGLE_BUTTON_HEIGHT = 40

-- Fonts
local titleFont
local toggleButtonFont
local playoffHeaderFont
local weekFont
local matchupFont
local scoreFont
local resultFont
local notPlayedFont
local conferenceHeaderFont
local bracketTeamFont

--- Initializes the schedule screen
function ScheduleScreen.load()
    -- Update UI scale
    UIScale.update()

    -- Create fonts
    titleFont = love.graphics.newFont(UIScale.scaleFontSize(32))
    toggleButtonFont = love.graphics.newFont(UIScale.scaleFontSize(18))
    playoffHeaderFont = love.graphics.newFont(UIScale.scaleFontSize(28))
    weekFont = love.graphics.newFont(UIScale.scaleFontSize(20))
    matchupFont = love.graphics.newFont(UIScale.scaleFontSize(22))
    scoreFont = love.graphics.newFont(UIScale.scaleFontSize(20))
    resultFont = love.graphics.newFont(UIScale.scaleFontSize(20))
    notPlayedFont = love.graphics.newFont(UIScale.scaleFontSize(18))
    conferenceHeaderFont = love.graphics.newFont(UIScale.scaleFontSize(24))
    bracketTeamFont = love.graphics.newFont(UIScale.scaleFontSize(16))

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

    local contentHeight = totalGames * UIScale.scaleHeight(GAME_ROW_HEIGHT)
    ScheduleScreen.maxScroll = math.max(0, contentHeight - UIScale.scaleHeight(ScheduleScreen.contentHeight))
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
        my = my - UIScale.scaleHeight(100)  -- Adjust for header

        local scaledToggleX = UIScale.scaleX(TOGGLE_BUTTON_X)
        local scaledToggleY = UIScale.scaleY(TOGGLE_BUTTON_Y)
        local scaledToggleWidth = UIScale.scaleWidth(TOGGLE_BUTTON_WIDTH)
        local scaledToggleHeight = UIScale.scaleHeight(TOGGLE_BUTTON_HEIGHT)

        local hovering = mx >= scaledToggleX and mx <= scaledToggleX + scaledToggleWidth and
                        my >= scaledToggleY and my <= scaledToggleY + scaledToggleHeight

        if hovering then
            love.graphics.setColor(0.3, 0.3, 0.4)
        else
            love.graphics.setColor(0.2, 0.2, 0.25)
        end
        love.graphics.rectangle("fill", scaledToggleX, scaledToggleY, scaledToggleWidth, scaledToggleHeight)

        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.setLineWidth(UIScale.scaleUniform(2))
        love.graphics.rectangle("line", scaledToggleX, scaledToggleY, scaledToggleWidth, scaledToggleHeight)

        love.graphics.setFont(toggleButtonFont)
        love.graphics.setColor(1, 1, 1)
        local buttonText = ScheduleScreen.showBracket and "Show Schedule" or "Show Bracket"
        local textWidth = toggleButtonFont:getWidth(buttonText)
        love.graphics.print(buttonText, scaledToggleX + (scaledToggleWidth - textWidth) / 2, scaledToggleY + UIScale.scaleHeight(10))
    end

    love.graphics.push()
    love.graphics.translate(0, -ScheduleScreen.scrollOffset)

    local yOffset = UIScale.scaleY(START_Y)
    local startX = UIScale.scaleX(START_X)

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    local title = ScheduleScreen.showBracket and "Playoff Bracket" or "Season Schedule"
    love.graphics.print(title, startX, yOffset)
    yOffset = yOffset + UIScale.scaleHeight(50)

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
    local startX = UIScale.scaleX(START_X)

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
        yOffset = yOffset + UIScale.scaleHeight(30)

        -- Section header
        love.graphics.setFont(playoffHeaderFont)
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.print("PLAYOFFS", startX, yOffset)
        yOffset = yOffset + UIScale.scaleHeight(40)

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

    local startX = UIScale.scaleX(START_X)
    local scaledGameWidth = UIScale.scaleWidth(GAME_WIDTH)
    local scaledGameRowHeight = UIScale.scaleHeight(GAME_ROW_HEIGHT)

    -- Background
    if hasPlayed then
        love.graphics.setColor(0.2, 0.2, 0.25)
    else
        love.graphics.setColor(0.15, 0.2, 0.25)
    end
    love.graphics.rectangle("fill", startX, y, scaledGameWidth, scaledGameRowHeight)

    -- Border
    if week == SeasonManager.currentWeek and not hasPlayed then
        love.graphics.setColor(0.8, 0.8, 0.3)  -- Highlight current week
        love.graphics.setLineWidth(UIScale.scaleUniform(3))
    else
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.setLineWidth(UIScale.scaleUniform(2))
    end
    love.graphics.rectangle("line", startX, y, scaledGameWidth, scaledGameRowHeight)

    -- Week label
    love.graphics.setFont(weekFont)
    love.graphics.setColor(0.7, 0.7, 0.8)

    local weekText = ""
    if isPlayoff then
        weekText = playoffRound or string.format("Week %d", week)
    else
        weekText = string.format("Week %d", week)
    end
    love.graphics.print(weekText, startX + UIScale.scaleUniform(15), y + UIScale.scaleHeight(12))

    -- Matchup
    love.graphics.setFont(matchupFont)
    love.graphics.setColor(1, 1, 1)

    local matchupText = ""
    if isPlayerHome then
        matchupText = string.format("%s vs %s", SeasonManager.playerTeam.name, opponent.name)
    else
        matchupText = string.format("%s @ %s", SeasonManager.playerTeam.name, opponent.name)
    end

    love.graphics.print(matchupText, startX + UIScale.scaleUniform(150), y + UIScale.scaleHeight(10))

    -- Result
    if hasPlayed then
        local playerScore = isPlayerHome and match.homeScore or match.awayScore
        local opponentScore = isPlayerHome and match.awayScore or match.homeScore
        local playerWon = playerScore > opponentScore

        -- Show score inline: "24 - 17 (W)" or "17 - 24 (L)"
        love.graphics.setFont(scoreFont)
        love.graphics.setColor(1, 1, 1)
        local scoreText = string.format("%d - %d ", playerScore, opponentScore)
        love.graphics.print(scoreText, startX + scaledGameWidth - UIScale.scaleUniform(150), y + UIScale.scaleHeight(12))

        -- W/L indicator
        love.graphics.setFont(resultFont)
        local scoreWidth = scoreFont:getWidth(scoreText)
        if playerWon then
            love.graphics.setColor(0.3, 0.8, 0.3)
            love.graphics.print("(W)", startX + scaledGameWidth - UIScale.scaleUniform(150) + scoreWidth, y + UIScale.scaleHeight(12))
        else
            love.graphics.setColor(0.8, 0.3, 0.3)
            love.graphics.print("(L)", startX + scaledGameWidth - UIScale.scaleUniform(150) + scoreWidth, y + UIScale.scaleHeight(12))
        end
    else
        love.graphics.setFont(notPlayedFont)
        love.graphics.setColor(0.6, 0.6, 0.7)
        love.graphics.print("Not played", startX + scaledGameWidth - UIScale.scaleUniform(120), y + UIScale.scaleHeight(14))
    end

    return y + scaledGameRowHeight
end

--- Draws the playoff bracket in a tree format
--- @param yOffset number Starting Y position
function ScheduleScreen.drawBracket(yOffset)
    local startX = UIScale.scaleX(START_X)

    if not SeasonManager.playoffBracket then
        love.graphics.setFont(conferenceHeaderFont)
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.print("Playoffs have not started yet", startX, yOffset)
        return
    end

    local bracket = SeasonManager.playoffBracket
    local MATCHUP_WIDTH = 200
    local MATCHUP_HEIGHT = 70
    local ROUND_SPACING = 250
    local MATCHUP_SPACING = 100

    -- Conference A bracket (top)
    local confAStartY = yOffset
    love.graphics.setFont(conferenceHeaderFont)
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.print("Conference A", startX, confAStartY)
    confAStartY = confAStartY + UIScale.scaleHeight(35)

    -- Conference B bracket (bottom)
    local confBStartY = confAStartY + UIScale.scaleHeight(400)
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.print("Conference B", startX, confBStartY)
    confBStartY = confBStartY + UIScale.scaleHeight(35)

    -- Draw Wild Card round (if exists)
    if bracket.wildcard and #bracket.wildcard > 0 then
        local x = startX
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
            local y = confAStartY + ((i - 1) * UIScale.scaleHeight(MATCHUP_HEIGHT + MATCHUP_SPACING))
            ScheduleScreen.drawBracketMatch(match, x, y, "wildcard")
        end

        -- Draw Conference B wildcard games
        for i, match in ipairs(confBWildcard) do
            local y = confBStartY + ((i - 1) * UIScale.scaleHeight(MATCHUP_HEIGHT + MATCHUP_SPACING))
            ScheduleScreen.drawBracketMatch(match, x, y, "wildcard")
        end
    end

    -- Draw Divisional round
    if bracket.divisional and #bracket.divisional > 0 then
        local x = startX + UIScale.scaleUniform(ROUND_SPACING)
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
            local y = confAStartY + UIScale.scaleHeight(50) + ((i - 1) * UIScale.scaleHeight(MATCHUP_HEIGHT + MATCHUP_SPACING * 2))
            ScheduleScreen.drawBracketMatch(match, x, y, "divisional")
        end

        for i, match in ipairs(confBDiv) do
            local y = confBStartY + UIScale.scaleHeight(50) + ((i - 1) * UIScale.scaleHeight(MATCHUP_HEIGHT + MATCHUP_SPACING * 2))
            ScheduleScreen.drawBracketMatch(match, x, y, "divisional")
        end
    end

    -- Draw Conference Championship
    if bracket.conference and #bracket.conference > 0 then
        local x = startX + UIScale.scaleUniform(ROUND_SPACING * 2)

        for i, match in ipairs(bracket.conference) do
            local y
            if match.homeTeam.conference == "A" then
                y = confAStartY + UIScale.scaleHeight(150)
            else
                y = confBStartY + UIScale.scaleHeight(150)
            end
            ScheduleScreen.drawBracketMatch(match, x, y, "conference")
        end
    end

    -- Draw Championship (center)
    if bracket.championship and #bracket.championship > 0 then
        local x = startX + UIScale.scaleUniform(ROUND_SPACING * 3)
        local y = (confAStartY + confBStartY) / 2 + UIScale.scaleHeight(50)
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
    local scaledMatchupWidth = UIScale.scaleWidth(MATCHUP_WIDTH)
    local scaledMatchupHeight = UIScale.scaleHeight(MATCHUP_HEIGHT)
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
    love.graphics.rectangle("fill", x, y, scaledMatchupWidth, scaledMatchupHeight)

    -- Border
    if hasPlayed and not isFutureRound then
        love.graphics.setColor(0.8, 0.8, 0.3)
        love.graphics.setLineWidth(UIScale.scaleUniform(3))
    else
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.setLineWidth(UIScale.scaleUniform(2))
    end
    love.graphics.rectangle("line", x, y, scaledMatchupWidth, scaledMatchupHeight)

    -- Team names and scores
    love.graphics.setFont(bracketTeamFont)

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
    love.graphics.print(homeText, x + UIScale.scaleUniform(10), y + UIScale.scaleHeight(10))

    if hasPlayed then
        love.graphics.print(tostring(match.homeScore), x + scaledMatchupWidth - UIScale.scaleUniform(30), y + UIScale.scaleHeight(10))
    end

    -- Away team
    local awayText = match.awayTeam.name
    if string.len(awayText) > 18 then
        awayText = string.sub(awayText, 1, 15) .. "..."
    end
    love.graphics.print(awayText, x + UIScale.scaleUniform(10), y + UIScale.scaleHeight(40))

    if hasPlayed then
        love.graphics.print(tostring(match.awayScore), x + scaledMatchupWidth - UIScale.scaleUniform(30), y + UIScale.scaleHeight(40))
    end

    -- Winner indicator (bold line would be drawn separately as connections)
    if hasPlayed then
        local winner = match.homeScore > match.awayScore and match.homeTeam or match.awayTeam
        if winner then
            love.graphics.setColor(0.3, 0.8, 0.3)
            love.graphics.setLineWidth(UIScale.scaleUniform(2))
            if winner == match.homeTeam then
                love.graphics.rectangle("line", x + UIScale.scaleUniform(5), y + UIScale.scaleHeight(5), scaledMatchupWidth - UIScale.scaleUniform(10), UIScale.scaleHeight(25))
            else
                love.graphics.rectangle("line", x + UIScale.scaleUniform(5), y + UIScale.scaleHeight(35), scaledMatchupWidth - UIScale.scaleUniform(10), UIScale.scaleHeight(25))
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
        local scaledToggleX = UIScale.scaleX(TOGGLE_BUTTON_X)
        local scaledToggleY = UIScale.scaleY(TOGGLE_BUTTON_Y)
        local scaledToggleWidth = UIScale.scaleWidth(TOGGLE_BUTTON_WIDTH)
        local scaledToggleHeight = UIScale.scaleHeight(TOGGLE_BUTTON_HEIGHT)

        if x >= scaledToggleX and x <= scaledToggleX + scaledToggleWidth and
           y >= scaledToggleY and y <= scaledToggleY + scaledToggleHeight then
            ScheduleScreen.showBracket = not ScheduleScreen.showBracket
        end
    end
end

--- Handles mouse wheel scrolling
--- @param y number Scroll amount
function ScheduleScreen.wheelmoved(y)
    ScheduleScreen.scrollOffset = ScheduleScreen.scrollOffset - (y * UIScale.scaleUniform(30))
    ScheduleScreen.scrollOffset = math.max(0, math.min(ScheduleScreen.scrollOffset, ScheduleScreen.maxScroll))
end

return ScheduleScreen
