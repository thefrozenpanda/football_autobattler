-- main.lua
local match = require("match")
local menu = require("menu")
local coachSelection = require("coach_selection")
local Coach = require("coach")

local gameState = "menu" -- "menu", "coach_selection", or "game"

function love.load()
    love.window.setTitle("The Gridiron Bazaar")
    love.window.setMode(1600, 900, {resizable=false})

    menu.load()
end

function love.update(dt)
    if gameState == "menu" then
        menu.update(dt)
        if menu.startGameRequested then
            gameState = "coach_selection"
            coachSelection.load()
            menu.startGameRequested = false
        end
    elseif gameState == "coach_selection" then
        coachSelection.update(dt)
        if coachSelection.coachSelected then
            -- Player selected a coach, now start the match
            local playerCoachId = coachSelection.selectedCoachId
            local aiCoach = Coach.getRandom()

            gameState = "game"
            match.load(playerCoachId, aiCoach.id)
            coachSelection.coachSelected = false
        elseif coachSelection.cancelSelection then
            -- Player pressed ESC, go back to menu
            gameState = "menu"
            menu.load()
            coachSelection.cancelSelection = false
        end
    elseif gameState == "game" then
        match.update(dt)
        if match.shouldReturnToMenu then
            gameState = "menu"
            menu.load()
            match.shouldReturnToMenu = false
        end
    end
end

function love.draw()
    if gameState == "menu" then
        menu.draw()
    elseif gameState == "coach_selection" then
        coachSelection.draw()
    elseif gameState == "game" then
        match.draw()
    end
end

function love.keypressed(key)
    if gameState == "menu" then
        menu.keypressed(key)
    elseif gameState == "coach_selection" then
        coachSelection.keypressed(key)
    elseif gameState == "game" then
        match.keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    if gameState == "menu" then
        menu.mousepressed(x, y, button)
    elseif gameState == "coach_selection" then
        coachSelection.mousepressed(x, y, button)
    elseif gameState == "game" then
        match.mousepressed(x, y, button)
    end
end

function love.mousemoved(x, y, dx, dy)
    if gameState == "menu" then
        menu.mousemoved(x, y)
    elseif gameState == "coach_selection" then
        coachSelection.mousemoved(x, y)
    elseif gameState == "game" then
        match.mousemoved(x, y)
    end
end
