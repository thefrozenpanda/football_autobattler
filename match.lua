-- match.lua
local match = {}

local timer = 0
local font
local phase = "Offense"
local fieldYards = 0
local matchTime = 60
local timeLeft = matchTime

function match.load()
    font = love.graphics.newFont(24)
    timer = 0
    timeLeft = matchTime
    phase = "Offense"
    fieldYards = 0
end

function match.update(dt)
    timer = timer + dt
    timeLeft = math.max(0, timeLeft - dt)

    -- Just a visual example of gameplay simulation:
    if timer >= 1 then
        fieldYards = fieldYards + love.math.random(0, 5)
        timer = 0
    end

    if timeLeft <= 0 then
        phase = "Match Over"
    end
end

function match.draw()
    love.graphics.clear(0.05, 0.15, 0.1, 1)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)

    love.graphics.printf("Match Active!", 0, 150, 800, "center")
    love.graphics.printf("Phase: " .. phase, 0, 250, 800, "center")
    love.graphics.printf("Yards: " .. fieldYards, 0, 300, 800, "center")
    love.graphics.printf(string.format("Time Left: %.1f", timeLeft), 0, 350, 800, "center")
end

function match.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

return match
