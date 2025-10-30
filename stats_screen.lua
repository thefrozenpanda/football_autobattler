--- stats_screen.lua
--- Stats Screen
---
--- Displays a sortable table of all player cards with their season statistics.
--- Stats tracked: Yards gained, TDs, Cards boosted, Times slowed, Times froze, Yards reduced
--- Can be sorted by position, number, or any stat column.
---
--- Dependencies: season_manager.lua, card.lua
--- Used by: season_menu.lua
--- LÖVE Callbacks: love.update, love.draw, love.mousepressed

local StatsScreen = {}

local SeasonManager = require("season_manager")
local Card = require("card")

-- State
StatsScreen.allCards = {}  -- Combined offensive + defensive cards
StatsScreen.sortColumn = "position"  -- Current sort column
StatsScreen.sortAscending = true  -- Sort direction
StatsScreen.scrollOffset = 0
StatsScreen.maxScroll = 0
StatsScreen.contentHeight = 700

-- UI configuration
local ROW_HEIGHT = 35
local HEADER_HEIGHT = 40
local START_Y = 20

-- Column definitions
local columns = {
    {id = "position", label = "Pos", x = 50, width = 80},
    {id = "number", label = "#", x = 130, width = 60},
    {id = "type", label = "Type", x = 190, width = 120},
    {id = "yardsGained", label = "Yards", x = 310, width = 80},
    {id = "touchdownsScored", label = "TDs", x = 390, width = 60},
    {id = "cardsBoosted", label = "Boosts", x = 450, width = 80},
    {id = "timesSlowed", label = "Slows", x = 530, width = 80},
    {id = "timesFroze", label = "Freezes", x = 610, width = 80},
    {id = "yardsReduced", label = "Yds Removed", x = 690, width = 120}
}

--- Initializes the stats screen
function StatsScreen.load()
    StatsScreen.allCards = {}
    StatsScreen.sortColumn = "position"
    StatsScreen.sortAscending = true
    StatsScreen.scrollOffset = 0

    -- Combine all cards
    if SeasonManager.playerTeam then
        for _, card in ipairs(SeasonManager.playerTeam.offensiveCards) do
            table.insert(StatsScreen.allCards, card)
        end
        for _, card in ipairs(SeasonManager.playerTeam.defensiveCards) do
            table.insert(StatsScreen.allCards, card)
        end
    end

    -- Initial sort
    StatsScreen.sortCards()
    StatsScreen.calculateMaxScroll()
end

--- Sorts the card list by the current sort column
function StatsScreen.sortCards()
    table.sort(StatsScreen.allCards, function(a, b)
        local valueA = StatsScreen.getCardValue(a, StatsScreen.sortColumn)
        local valueB = StatsScreen.getCardValue(b, StatsScreen.sortColumn)

        if valueA == valueB then
            -- Secondary sort by number
            return a.number < b.number
        end

        if StatsScreen.sortAscending then
            return valueA < valueB
        else
            return valueA > valueB
        end
    end)
end

--- Gets a card's value for a given column
--- @param card table The card
--- @param column string The column ID
--- @return any The value for sorting
function StatsScreen.getCardValue(card, column)
    if column == "position" then
        return card.position
    elseif column == "number" then
        return card.number
    elseif column == "type" then
        return card.cardType
    elseif column == "yardsGained" then
        return card.yardsGained or 0
    elseif column == "touchdownsScored" then
        return card.touchdownsScored or 0
    elseif column == "cardsBoosted" then
        return card.cardsBoosted or 0
    elseif column == "timesSlowed" then
        return card.timesSlowed or 0
    elseif column == "timesFroze" then
        return card.timesFroze or 0
    elseif column == "yardsReduced" then
        return card.yardsReduced or 0
    end
    return 0
end

--- Calculates the maximum scroll amount
function StatsScreen.calculateMaxScroll()
    local contentHeight = HEADER_HEIGHT + (#StatsScreen.allCards * ROW_HEIGHT) + 100
    StatsScreen.maxScroll = math.max(0, contentHeight - StatsScreen.contentHeight)
end

--- LÖVE Callback: Update Logic
--- @param dt number Delta time in seconds
function StatsScreen.update(dt)
    -- Nothing to update
end

--- LÖVE Callback: Draw UI
function StatsScreen.draw()
    love.graphics.push()
    love.graphics.translate(0, -StatsScreen.scrollOffset)

    -- Title
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Season Statistics", 50, START_Y)

    local yOffset = START_Y + 50

    -- Draw table header
    StatsScreen.drawTableHeader(yOffset)
    yOffset = yOffset + HEADER_HEIGHT

    -- Draw table rows
    for i, card in ipairs(StatsScreen.allCards) do
        StatsScreen.drawTableRow(card, yOffset, i % 2 == 0)
        yOffset = yOffset + ROW_HEIGHT
    end

    love.graphics.pop()
end

--- Draws the table header with column names
--- @param y number Y position
function StatsScreen.drawTableHeader(y)
    local mx, my = love.mouse.getPosition()
    my = my - 100  -- Adjust for header

    -- Header background
    love.graphics.setColor(0.2, 0.25, 0.3)
    love.graphics.rectangle("fill", columns[1].x, y, columns[#columns].x + columns[#columns].width - columns[1].x, HEADER_HEIGHT)

    love.graphics.setFont(love.graphics.newFont(20))

    for _, col in ipairs(columns) do
        local hovering = mx >= col.x and mx <= col.x + col.width and
                        my >= y and my <= y + HEADER_HEIGHT

        -- Highlight if hovering
        if hovering then
            love.graphics.setColor(0.3, 0.4, 0.5)
            love.graphics.rectangle("fill", col.x, y, col.width, HEADER_HEIGHT)
        end

        -- Column text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(col.label, col.x + 10, y + 10)

        -- Sort indicator
        if StatsScreen.sortColumn == col.id then
            local arrow = StatsScreen.sortAscending and "▲" or "▼"
            love.graphics.setColor(0.8, 0.8, 1)
            love.graphics.print(arrow, col.x + col.width - 20, y + 10)
        end

        -- Border
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.line(col.x + col.width, y, col.x + col.width, y + HEADER_HEIGHT)
    end
end

--- Draws a table row for a card
--- @param card table The card
--- @param y number Y position
--- @param alternate boolean Whether this is an alternate row
function StatsScreen.drawTableRow(card, y, alternate)
    -- Background
    if alternate then
        love.graphics.setColor(0.18, 0.18, 0.22)
    else
        love.graphics.setColor(0.15, 0.15, 0.2)
    end
    love.graphics.rectangle("fill", columns[1].x, y, columns[#columns].x + columns[#columns].width - columns[1].x, ROW_HEIGHT)

    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(0.9, 0.9, 1)

    for _, col in ipairs(columns) do
        local value = ""

        if col.id == "position" then
            value = card.position
        elseif col.id == "number" then
            value = string.format("#%d", card.number)
        elseif col.id == "type" then
            if card.cardType == Card.TYPE.YARD_GENERATOR then
                value = "Generator"
            elseif card.cardType == Card.TYPE.BOOSTER then
                value = "Booster"
            elseif card.cardType == Card.TYPE.DEFENDER then
                value = "Defender"
            end
        elseif col.id == "yardsGained" then
            value = string.format("%.0f", card.yardsGained or 0)
        elseif col.id == "touchdownsScored" then
            value = tostring(card.touchdownsScored or 0)
        elseif col.id == "cardsBoosted" then
            value = tostring(card.cardsBoosted or 0)
        elseif col.id == "timesSlowed" then
            value = tostring(card.timesSlowed or 0)
        elseif col.id == "timesFroze" then
            value = tostring(card.timesFroze or 0)
        elseif col.id == "yardsReduced" then
            value = string.format("%.0f", card.yardsReduced or 0)
        end

        love.graphics.print(value, col.x + 10, y + 8)
    end

    -- Row border
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.setLineWidth(1)
    love.graphics.line(columns[1].x, y + ROW_HEIGHT, columns[#columns].x + columns[#columns].width, y + ROW_HEIGHT)
end

--- LÖVE Callback: Mouse Pressed
--- @param x number Mouse X position
--- @param y number Mouse Y position
--- @param button number Mouse button
function StatsScreen.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    -- Check if clicking on header to sort
    local headerY = START_Y + 50 - StatsScreen.scrollOffset

    if y >= headerY and y <= headerY + HEADER_HEIGHT then
        for _, col in ipairs(columns) do
            if x >= col.x and x <= col.x + col.width then
                -- Toggle sort
                if StatsScreen.sortColumn == col.id then
                    StatsScreen.sortAscending = not StatsScreen.sortAscending
                else
                    StatsScreen.sortColumn = col.id
                    StatsScreen.sortAscending = false  -- Default to descending for stats
                end

                StatsScreen.sortCards()
                return
            end
        end
    end
end

--- Handles mouse wheel scrolling
--- @param y number Scroll amount
function StatsScreen.wheelmoved(y)
    StatsScreen.scrollOffset = StatsScreen.scrollOffset - (y * 30)
    StatsScreen.scrollOffset = math.max(0, math.min(StatsScreen.scrollOffset, StatsScreen.maxScroll))
end

return StatsScreen
