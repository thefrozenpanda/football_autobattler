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
local UIScale = require("ui_scale")

-- State
StandingsScreen.sortColumn = "position"  -- Current sort column
StandingsScreen.sortAscending = true  -- Sort direction
StandingsScreen.contentHeight = 700

-- UI configuration (base values for 1600x900)
local COLUMN_START_X = 50
local ROW_HEIGHT = 35
local HEADER_HEIGHT = 40
local CONFERENCE_WIDTH = 700
local CONFERENCE_SPACING = 100

-- Column definitions for each conference (base widths for 1600x900)
local columns = {
    {id = "position", label = "Seed", width = 60},
    {id = "team", label = "Team", width = 250},
    {id = "record", label = "W-L", width = 80},
    {id = "pointDiff", label = "Diff", width = 80},
    {id = "playoff", label = "Playoffs", width = 100}
}

-- Fonts
local titleFont
local conferenceFont
local headerFont
local rowFont
local rowFontBold

--- Initializes the standings screen
function StandingsScreen.load()
    -- Update UI scale
    UIScale.update()

    -- Create fonts
    titleFont = love.graphics.newFont(UIScale.scaleFontSize(32))
    conferenceFont = love.graphics.newFont(UIScale.scaleFontSize(28))
    headerFont = love.graphics.newFont(UIScale.scaleFontSize(18))
    rowFont = love.graphics.newFont(UIScale.scaleFontSize(18))
    rowFontBold = love.graphics.newFont(UIScale.scaleFontSize(20))

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
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    local titleText = "Conference Standings"
    local titleWidth = titleFont:getWidth(titleText)
    love.graphics.print(titleText, (UIScale.getWidth() - titleWidth) / 2, UIScale.scaleY(20))

    local yOffset = UIScale.scaleY(80)

    -- Draw Conference A
    local scaledStartX = UIScale.scaleX(COLUMN_START_X)
    local scaledConferenceWidth = UIScale.scaleWidth(CONFERENCE_WIDTH)
    local scaledSpacing = UIScale.scaleUniform(CONFERENCE_SPACING)

    StandingsScreen.drawConference("A", scaledStartX, yOffset)

    -- Draw Conference B
    StandingsScreen.drawConference("B", scaledStartX + scaledConferenceWidth + scaledSpacing, yOffset)
end

--- Draws a single conference standings
--- @param conference string "A" or "B"
--- @param x number X position
--- @param y number Y position
function StandingsScreen.drawConference(conference, x, y)
    -- Conference header
    love.graphics.setFont(conferenceFont)
    love.graphics.setColor(0.8, 0.9, 1)
    local headerText = "Conference " .. conference
    love.graphics.print(headerText, x, y)

    y = y + UIScale.scaleHeight(45)

    -- Get standings
    local standings = SeasonManager.getStandings(conference)

    -- Draw table header
    StandingsScreen.drawTableHeader(x, y)
    y = y + UIScale.scaleHeight(HEADER_HEIGHT)

    -- Draw rows
    local scaledRowHeight = UIScale.scaleHeight(ROW_HEIGHT)
    for i, team in ipairs(standings) do
        StandingsScreen.drawTeamRow(team, i, x, y, i % 2 == 0)
        y = y + scaledRowHeight
    end
end

--- Draws the table header
--- @param x number X position
--- @param y number Y position
function StandingsScreen.drawTableHeader(x, y)
    -- Header background
    love.graphics.setColor(0.2, 0.25, 0.3)
    local scaledConferenceWidth = UIScale.scaleWidth(CONFERENCE_WIDTH)
    local scaledHeaderHeight = UIScale.scaleHeight(HEADER_HEIGHT)
    love.graphics.rectangle("fill", x, y, scaledConferenceWidth, scaledHeaderHeight)

    love.graphics.setFont(headerFont)

    local currentX = x + UIScale.scaleUniform(10)

    for _, col in ipairs(columns) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(col.label, currentX, y + UIScale.scaleHeight(10))

        currentX = currentX + UIScale.scaleWidth(col.width)
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
    local scaledConferenceWidth = UIScale.scaleWidth(CONFERENCE_WIDTH)
    local scaledRowHeight = UIScale.scaleHeight(ROW_HEIGHT)

    if isPlayerTeam then
        love.graphics.setColor(0.3, 0.4, 0.5)  -- Highlighted for player
    elseif alternate then
        love.graphics.setColor(0.18, 0.18, 0.22)
    else
        love.graphics.setColor(0.15, 0.15, 0.2)
    end
    love.graphics.rectangle("fill", x, y, scaledConferenceWidth, scaledRowHeight)

    -- Font selection (bold for player team)
    love.graphics.setFont(isPlayerTeam and rowFontBold or rowFont)

    local currentX = x + UIScale.scaleUniform(10)
    local yOffset = y + UIScale.scaleHeight(8)

    -- Position/Seed
    love.graphics.setColor(0.9, 0.9, 1)
    love.graphics.print(tostring(position), currentX, yOffset)
    currentX = currentX + UIScale.scaleWidth(columns[1].width)

    -- Team name (truncate if too long to prevent clipping)
    if isPlayerTeam then
        love.graphics.setColor(1, 1, 0.8)  -- Slight yellow tint for player
    else
        love.graphics.setColor(0.9, 0.9, 1)
    end
    local teamName = team.name
    local maxChars = 20  -- Maximum characters before truncation
    if string.len(teamName) > maxChars then
        teamName = string.sub(teamName, 1, maxChars - 3) .. "..."
    end
    love.graphics.print(teamName, currentX, yOffset)
    currentX = currentX + UIScale.scaleWidth(columns[2].width)

    -- Record
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.print(team:getRecordString(), currentX, yOffset)
    currentX = currentX + UIScale.scaleWidth(columns[3].width)

    -- Point Differential
    local pointDiff = team:getPointDifferential()
    if pointDiff > 0 then
        love.graphics.setColor(0.3, 0.8, 0.3)
        love.graphics.print("+" .. tostring(pointDiff), currentX, yOffset)
    elseif pointDiff < 0 then
        love.graphics.setColor(0.8, 0.3, 0.3)
        love.graphics.print(tostring(pointDiff), currentX, yOffset)
    else
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.print("0", currentX, yOffset)
    end
    currentX = currentX + UIScale.scaleWidth(columns[4].width)

    -- Playoff indicator
    if position <= 6 then
        if position <= 2 then
            -- Gold star for top 2 seeds (bye week)
            love.graphics.setColor(1, 0.8, 0.2)
            love.graphics.print("★ BYE", currentX, yOffset)
        else
            -- Silver star for seeds 3-6
            love.graphics.setColor(0.7, 0.7, 0.8)
            love.graphics.print("★ WC", currentX, yOffset)
        end
    else
        -- No playoff spot
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.print("---", currentX, yOffset)
    end

    -- Row border
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.setLineWidth(UIScale.scaleUniform(1))
    love.graphics.line(x, y + scaledRowHeight, x + scaledConferenceWidth, y + scaledRowHeight)
end

--- LÖVE Callback: Mouse Pressed
--- @param x number Mouse X position
--- @param y number Mouse Y position
--- @param button number Mouse button
function StandingsScreen.mousepressed(x, y, button)
    -- Static display for now, no click interactions
end

return StandingsScreen
