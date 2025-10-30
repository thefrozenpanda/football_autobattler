--- standings_screen.lua
--- Conference Standings Screen
---
--- Displays both Conference A and B standings side-by-side with:
--- - Team name, W-L record, point differential
--- - Position in standings (1-9)
--- - Playoff indicators (gold stars for seeds 1-2, silver for 3-6)
--- - Player's team highlighted and bolded
--- - Sortable columns
---
--- Dependencies: season_manager.lua, team.lua
--- Used by: season_menu.lua
--- LÖVE Callbacks: love.update, love.draw, love.mousepressed

local StandingsScreen = {}

local SeasonManager = require("season_manager")
local Team = require("team")

-- State
StandingsScreen.sortColumn = "position"  -- Current sort column
StandingsScreen.sortAscending = true  -- Sort direction
StandingsScreen.contentHeight = 700

-- UI configuration
local COLUMN_START_X = 50
local ROW_HEIGHT = 35
local HEADER_HEIGHT = 40
local CONFERENCE_WIDTH = 700
local CONFERENCE_SPACING = 100

-- Column definitions for each conference
local columns = {
    {id = "position", label = "Seed", width = 60},
    {id = "team", label = "Team", width = 250},
    {id = "record", label = "W-L", width = 80},
    {id = "pointDiff", label = "Diff", width = 80},
    {id = "playoff", label = "Playoffs", width = 100}
}

--- Initializes the standings screen
function StandingsScreen.load()
    StandingsScreen.sortColumn = "position"
    StandingsScreen.sortAscending = true
end

--- LÖVE Callback: Update Logic
--- @param dt number Delta time in seconds
function StandingsScreen.update(dt)
    -- Nothing to update
end

--- LÖVE Callback: Draw UI
function StandingsScreen.draw()
    -- Title
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.setColor(1, 1, 1)
    local titleText = "Conference Standings"
    local titleWidth = love.graphics.getFont():getWidth(titleText)
    love.graphics.print(titleText, (1600 - titleWidth) / 2, 20)

    local yOffset = 80

    -- Draw Conference A
    StandingsScreen.drawConference("A", COLUMN_START_X, yOffset)

    -- Draw Conference B
    StandingsScreen.drawConference("B", COLUMN_START_X + CONFERENCE_WIDTH + CONFERENCE_SPACING, yOffset)
end

--- Draws a single conference standings
--- @param conference string "A" or "B"
--- @param x number X position
--- @param y number Y position
function StandingsScreen.drawConference(conference, x, y)
    -- Conference header
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.setColor(0.8, 0.9, 1)
    local headerText = "Conference " .. conference
    love.graphics.print(headerText, x, y)

    y = y + 45

    -- Get standings
    local standings = SeasonManager.getStandings(conference)

    -- Draw table header
    StandingsScreen.drawTableHeader(x, y)
    y = y + HEADER_HEIGHT

    -- Draw rows
    for i, team in ipairs(standings) do
        StandingsScreen.drawTeamRow(team, i, x, y, i % 2 == 0)
        y = y + ROW_HEIGHT
    end
end

--- Draws the table header
--- @param x number X position
--- @param y number Y position
function StandingsScreen.drawTableHeader(x, y)
    -- Header background
    love.graphics.setColor(0.2, 0.25, 0.3)
    love.graphics.rectangle("fill", x, y, CONFERENCE_WIDTH, HEADER_HEIGHT)

    love.graphics.setFont(love.graphics.newFont(18))

    local currentX = x + 10

    for _, col in ipairs(columns) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(col.label, currentX, y + 10)

        currentX = currentX + col.width
    end
end

--- Draws a single team row
--- @param team table The team
--- @param position number Position in standings (1-9)
--- @param x number X position
--- @param y number Y position
--- @param alternate boolean Whether this is an alternate row
function StandingsScreen.drawTeamRow(team, position, x, y, alternate)
    local isPlayerTeam = (team == SeasonManager.playerTeam)

    -- Background
    if isPlayerTeam then
        love.graphics.setColor(0.3, 0.4, 0.5)  -- Highlighted for player
    elseif alternate then
        love.graphics.setColor(0.18, 0.18, 0.22)
    else
        love.graphics.setColor(0.15, 0.15, 0.2)
    end
    love.graphics.rectangle("fill", x, y, CONFERENCE_WIDTH, ROW_HEIGHT)

    -- Font selection (bold for player team)
    local fontSize = isPlayerTeam and 20 or 18
    love.graphics.setFont(love.graphics.newFont(fontSize))

    local currentX = x + 10

    -- Position/Seed
    love.graphics.setColor(0.9, 0.9, 1)
    love.graphics.print(tostring(position), currentX, y + 8)
    currentX = currentX + columns[1].width

    -- Team name
    if isPlayerTeam then
        love.graphics.setColor(1, 1, 0.8)  -- Slight yellow tint for player
    else
        love.graphics.setColor(0.9, 0.9, 1)
    end
    love.graphics.print(team.name, currentX, y + 8)
    currentX = currentX + columns[2].width

    -- Record
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.print(team:getRecordString(), currentX, y + 8)
    currentX = currentX + columns[3].width

    -- Point Differential
    local pointDiff = team:getPointDifferential()
    if pointDiff > 0 then
        love.graphics.setColor(0.3, 0.8, 0.3)
        love.graphics.print("+" .. tostring(pointDiff), currentX, y + 8)
    elseif pointDiff < 0 then
        love.graphics.setColor(0.8, 0.3, 0.3)
        love.graphics.print(tostring(pointDiff), currentX, y + 8)
    else
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.print("0", currentX, y + 8)
    end
    currentX = currentX + columns[4].width

    -- Playoff indicator
    if position <= 6 then
        if position <= 2 then
            -- Gold star for top 2 seeds (bye week)
            love.graphics.setColor(1, 0.8, 0.2)
            love.graphics.print("★ BYE", currentX, y + 8)
        else
            -- Silver star for seeds 3-6
            love.graphics.setColor(0.7, 0.7, 0.8)
            love.graphics.print("★ WC", currentX, y + 8)
        end
    else
        -- No playoff spot
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.print("---", currentX, y + 8)
    end

    -- Row border
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.setLineWidth(1)
    love.graphics.line(x, y + ROW_HEIGHT, x + CONFERENCE_WIDTH, y + ROW_HEIGHT)
end

--- LÖVE Callback: Mouse Pressed
--- @param x number Mouse X position
--- @param y number Mouse Y position
--- @param button number Mouse button
function StandingsScreen.mousepressed(x, y, button)
    -- Static display for now, no click interactions
end

return StandingsScreen
