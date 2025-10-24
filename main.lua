-- main.lua
local match = require("match")
local menu = require("menu")

local gameState = "menu" -- "menu" or "game"

function love.load()
    love.window.setTitle("American Football Battler")
    love.window.setMode(800, 600, {resizable=false})
    
    menu.load()
end

function love.update(dt)
    if gameState == "menu" then
        menu.update(dt)
        if menu.startGameRequested then
            gameState = "game"
            match.load()
        end
    elseif gameState == "game" then
        match.update(dt)
    end
end

function love.draw()
    if gameState == "menu" then
        menu.draw()
    elseif gameState == "game" then
        match.draw()
    end
end

function love.keypressed(key)
    if gameState == "menu" then
        menu.keypressed(key)
    elseif gameState == "game" then
        match.keypressed(key)
    end
end
