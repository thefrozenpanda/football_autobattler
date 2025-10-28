-- coach_selection.lua
local Coach = require("coach")

local coachSelection = {}

coachSelection.selectedCoachId = nil
local titleFont
local nameFont
local descFont
local selectedIndex = 0  -- 0 means no selection

-- Card layout
local CARD_WIDTH = 320
local CARD_HEIGHT = 400
local CARD_PADDING = 40
local CARD_START_X = 80

function coachSelection.load()
    titleFont = love.graphics.newFont(36)
    nameFont = love.graphics.newFont(24)
    descFont = love.graphics.newFont(14)
    selectedIndex = 0
    coachSelection.selectedCoachId = nil
end

function coachSelection.update(dt)
    -- Static screen, no updates needed
end

function coachSelection.draw()
    love.graphics.clear(0.1, 0.15, 0.2, 1)

    -- Draw title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Select Your Coach", 0, 50, 1600, "center")

    -- Draw subtitle
    love.graphics.setFont(descFont)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("Choose your coaching philosophy to begin", 0, 110, 1600, "center")

    -- Draw coach cards
    for i, coach in ipairs(Coach.types) do
        local x = CARD_START_X + (i - 1) * (CARD_WIDTH + CARD_PADDING)
        local y = 200

        coachSelection.drawCoachCard(coach, x, y, i == selectedIndex)
    end

    -- Draw instructions
    love.graphics.setFont(descFont)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.printf("Use Arrow Keys or Mouse - Enter or Click to Select", 0, 820, 1600, "center")
end

function coachSelection.drawCoachCard(coach, x, y, isSelected)
    -- Background
    love.graphics.setColor(0.15, 0.2, 0.25)
    love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT, 10, 10)

    -- Border
    if isSelected then
        love.graphics.setColor(coach.color[1], coach.color[2], coach.color[3])
        love.graphics.setLineWidth(4)
    else
        love.graphics.setColor(0.4, 0.5, 0.6)
        love.graphics.setLineWidth(2)
    end
    love.graphics.rectangle("line", x, y, CARD_WIDTH, CARD_HEIGHT, 10, 10)

    -- Coach color accent bar at top
    love.graphics.setColor(coach.color[1], coach.color[2], coach.color[3], 0.6)
    love.graphics.rectangle("fill", x, y, CARD_WIDTH, 8, 10, 10)

    -- Coach name
    love.graphics.setFont(nameFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(coach.name, x, y + 20, CARD_WIDTH, "center")

    -- Description
    love.graphics.setFont(descFont)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf(coach.description, x + 10, y + 60, CARD_WIDTH - 20, "center")

    -- Signature ability
    love.graphics.setColor(coach.color[1], coach.color[2], coach.color[3])
    love.graphics.printf("Signature:", x + 10, y + 110, CARD_WIDTH - 20, "left")

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(coach.signature, x + 10, y + 130, CARD_WIDTH - 20, "left")

    love.graphics.setFont(descFont)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf(coach.signatureDesc, x + 10, y + 155, CARD_WIDTH - 20, "left")

    -- Offensive preview
    love.graphics.setColor(0.9, 0.6, 0.3)
    love.graphics.printf("Offense:", x + 10, y + 195, CARD_WIDTH - 20, "left")
    love.graphics.setColor(0.8, 0.8, 0.8)
    local offenseText = ""
    for idx, card in ipairs(coach.offensiveCards) do
        offenseText = offenseText .. card.position
        if idx < #coach.offensiveCards then
            offenseText = offenseText .. ", "
        end
    end
    love.graphics.printf(offenseText, x + 10, y + 215, CARD_WIDTH - 20, "left")

    -- Defensive preview
    love.graphics.setColor(0.3, 0.6, 0.9)
    love.graphics.printf("Defense:", x + 10, y + 235, CARD_WIDTH - 20, "left")
    love.graphics.setColor(0.8, 0.8, 0.8)
    local defenseText = ""
    for idx, card in ipairs(coach.defensiveCards) do
        defenseText = defenseText .. card.position
        if idx < #coach.defensiveCards then
            defenseText = defenseText .. ", "
        end
    end
    love.graphics.printf(defenseText, x + 10, y + 255, CARD_WIDTH - 20, "left")
end

function coachSelection.keypressed(key)
    if key == "left" then
        selectedIndex = selectedIndex - 1
        if selectedIndex < 1 then
            selectedIndex = #Coach.types
        end
    elseif key == "right" then
        selectedIndex = selectedIndex + 1
        if selectedIndex > #Coach.types then
            selectedIndex = 1
        end
    elseif key == "return" or key == "space" then
        if selectedIndex > 0 then
            coachSelection.selectCoach(selectedIndex)
        end
    elseif key == "escape" then
        -- Go back to main menu
        coachSelection.cancelSelection = true
    end
end

function coachSelection.mousepressed(x, y, button)
    if button == 1 then
        -- Check if clicking on a coach card
        for i = 1, #Coach.types do
            local cardX = CARD_START_X + (i - 1) * (CARD_WIDTH + CARD_PADDING)
            local cardY = 120

            if x >= cardX and x <= cardX + CARD_WIDTH and
               y >= cardY and y <= cardY + CARD_HEIGHT then
                coachSelection.selectCoach(i)
                break
            end
        end
    end
end

function coachSelection.mousemoved(x, y)
    selectedIndex = 0  -- Reset selection

    -- Check if hovering over a coach card
    for i = 1, #Coach.types do
        local cardX = CARD_START_X + (i - 1) * (CARD_WIDTH + CARD_PADDING)
        local cardY = 120

        if x >= cardX and x <= cardX + CARD_WIDTH and
           y >= cardY and y <= cardY + CARD_HEIGHT then
            selectedIndex = i
            break
        end
    end
end

function coachSelection.selectCoach(index)
    local coach = Coach.types[index]
    coachSelection.selectedCoachId = coach.id
    coachSelection.coachSelected = true
end

return coachSelection
