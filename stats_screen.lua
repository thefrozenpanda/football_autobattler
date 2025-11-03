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
local UIScale = require("ui_scale")

-- State
StatsScreen.allCards = {}  -- Combined offensive + defensive cards
StatsScreen.sortColumn = "position"  -- Current sort column
StatsScreen.sortAscending = true  -- Sort direction
StatsScreen.scrollOffset = 0
StatsScreen.maxScroll = 0
StatsScreen.contentHeight = 700

-- UI configuration (base values for 1600x900)
local ROW_HEIGHT = 35
local HEADER_HEIGHT = 40
local START_Y = 20

-- Column definitions (base values for 1600x900)
local columns = {
    {id = "position", label = "Pos", x = 50, width = 100},
    {id = "number", label = "#", x = 150, width = 80},
    {id = "yardsGained", label = "Yards", x = 230, width = 110},
    {id = "touchdownsScored", label = "TDs", x = 340, width = 90},
    {id = "cardsBoosted", label = "Boosts", x = 430, width = 110},
    {id = "timesSlowed", label = "Slows", x = 540, width = 110},
    {id = "timesFroze", label = "Freezes", x = 650, width = 120},
    {id = "yardsReduced", label = "Yds Removed", x = 770, width = 150}
}

-- Fonts
local titleFont
local headerFont
local rowFont

--- Initializes the stats screen
function StatsScreen.load()
    -- Update UI scale
    UIScale.update()

    -- Create fonts
    titleFont = love.graphics.newFont(UIScale.scaleFontSize(32))
    headerFont = love.graphics.newFont(UIScale.scaleFontSize(20))
    rowFont = love.graphics.newFont(UIScale.scaleFontSize(18))

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
    local scaledHeaderHeight = UIScale.scaleHeight(HEADER_HEIGHT)
    local scaledRowHeight = UIScale.scaleHeight(ROW_HEIGHT)
    local contentHeight = scaledHeaderHeight + (#StatsScreen.allCards * scaledRowHeight) + UIScale.scaleHeight(100)
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
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Season Statistics", UIScale.scaleX(50), UIScale.scaleY(START_Y))

    local yOffset = UIScale.scaleY(START_Y + 50)

    -- Draw table header
    StatsScreen.drawTableHeader(yOffset)
    yOffset = yOffset + UIScale.scaleHeight(HEADER_HEIGHT)

    -- Draw table rows
    local scaledRowHeight = UIScale.scaleHeight(ROW_HEIGHT)
    for i, card in ipairs(StatsScreen.allCards) do
        StatsScreen.drawTableRow(card, yOffset, i % 2 == 0)
        yOffset = yOffset + scaledRowHeight
    end

    love.graphics.pop()
end

--- Draws the table header with column names
--- @param y number Y position
function StatsScreen.drawTableHeader(y)
    local mx, my = love.mouse.getPosition()
    my = my - UIScale.scaleY(100)  -- Adjust for header

    local scaledHeaderHeight = UIScale.scaleHeight(HEADER_HEIGHT)

    -- Calculate header background dimensions
    local firstColX = UIScale.scaleX(columns[1].x)
    local lastCol = columns[#columns]
    local headerWidth = UIScale.scaleX(lastCol.x + lastCol.width) - firstColX

    -- Header background
    love.graphics.setColor(0.2, 0.25, 0.3)
    love.graphics.rectangle("fill", firstColX, y, headerWidth, scaledHeaderHeight)

    love.graphics.setFont(headerFont)

    for _, col in ipairs(columns) do
        local scaledX = UIScale.scaleX(col.x)
        local scaledWidth = UIScale.scaleWidth(col.width)

        local hovering = mx >= scaledX and mx <= scaledX + scaledWidth and
                        my >= y and my <= y + scaledHeaderHeight

        -- Highlight if hovering
        if hovering then
            love.graphics.setColor(0.3, 0.4, 0.5)
            love.graphics.rectangle("fill", scaledX, y, scaledWidth, scaledHeaderHeight)
        end

        -- Column text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(col.label, scaledX + UIScale.scaleUniform(10), y + UIScale.scaleHeight(10))

        -- Sort indicator (triangle)
        if StatsScreen.sortColumn == col.id then
            love.graphics.setColor(0.8, 0.8, 1)
            local arrowX = scaledX + scaledWidth - UIScale.scaleUniform(15)
            local arrowY = y + scaledHeaderHeight / 2
            local arrowSize = UIScale.scaleUniform(5)
            local arrowOffset = UIScale.scaleUniform(3)

            if StatsScreen.sortAscending then
                -- Ascending: upward triangle ▲
                love.graphics.polygon("fill",
                    arrowX, arrowY - arrowSize,      -- top point
                    arrowX - arrowSize, arrowY + arrowOffset,  -- bottom left
                    arrowX + arrowSize, arrowY + arrowOffset   -- bottom right
                )
            else
                -- Descending: downward triangle ▼
                love.graphics.polygon("fill",
                    arrowX, arrowY + arrowSize,      -- bottom point
                    arrowX - arrowSize, arrowY - arrowOffset,  -- top left
                    arrowX + arrowSize, arrowY - arrowOffset   -- top right
                )
            end
        end

        -- Border
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.setLineWidth(UIScale.scaleUniform(1))
        love.graphics.line(scaledX + scaledWidth, y, scaledX + scaledWidth, y + scaledHeaderHeight)
    end
end

--- Draws a table row for a card
--- @param card table The card
--- @param y number Y position
--- @param alternate boolean Whether this is an alternate row
function StatsScreen.drawTableRow(card, y, alternate)
    -- Calculate dimensions
    local firstColX = UIScale.scaleX(columns[1].x)
    local lastCol = columns[#columns]
    local rowWidth = UIScale.scaleX(lastCol.x + lastCol.width) - firstColX
    local scaledRowHeight = UIScale.scaleHeight(ROW_HEIGHT)

    -- Background
    if alternate then
        love.graphics.setColor(0.18, 0.18, 0.22)
    else
        love.graphics.setColor(0.15, 0.15, 0.2)
    end
    love.graphics.rectangle("fill", firstColX, y, rowWidth, scaledRowHeight)

    love.graphics.setFont(rowFont)
    love.graphics.setColor(0.9, 0.9, 1)

    for _, col in ipairs(columns) do
        local value = ""

        if col.id == "position" then
            value = card.position
        elseif col.id == "number" then
            value = string.format("#%d", card.number)
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

        love.graphics.print(value, UIScale.scaleX(col.x) + UIScale.scaleUniform(10), y + UIScale.scaleHeight(8))
    end

    -- Row border
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.setLineWidth(UIScale.scaleUniform(1))
    love.graphics.line(firstColX, y + scaledRowHeight, firstColX + rowWidth, y + scaledRowHeight)
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
    local headerY = UIScale.scaleY(START_Y + 50) - StatsScreen.scrollOffset
    local scaledHeaderHeight = UIScale.scaleHeight(HEADER_HEIGHT)

    if y >= headerY and y <= headerY + scaledHeaderHeight then
        for _, col in ipairs(columns) do
            local scaledX = UIScale.scaleX(col.x)
            local scaledWidth = UIScale.scaleWidth(col.width)

            if x >= scaledX and x <= scaledX + scaledWidth then
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
    local scrollSpeed = UIScale.scaleUniform(30)
    StatsScreen.scrollOffset = StatsScreen.scrollOffset - (y * scrollSpeed)
    StatsScreen.scrollOffset = math.max(0, math.min(StatsScreen.scrollOffset, StatsScreen.maxScroll))
end

return StatsScreen
