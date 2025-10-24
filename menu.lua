-- menu.lua
local menu = {}

menu.startGameRequested = false
local titleFont
local promptFont
local blinkTimer = 0
local showPrompt = true

function menu.load()
    titleFont = love.graphics.newFont(48)
    promptFont = love.graphics.newFont(24)
end

function menu.update(dt)
    blinkTimer = blinkTimer + dt
    if blinkTimer >= 0.6 then
        blinkTimer = 0
        showPrompt = not showPrompt
    end
end

function menu.draw()
    love.graphics.setBackgroundColor(0.1, 0.15, 0.25)
    
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("American Football Battler", 0, 200, 800, "center")

    if showPrompt then
        love.graphics.setFont(promptFont)
        love.graphics.printf("Press SPACE to Start", 0, 400, 800, "center")
    end

    love.graphics.setFont(promptFont)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf("© 2025 Your Studio Name", 0, 560, 800, "center")
end

function menu.keypressed(key)
    if key == "space" then
        menu.startGameRequested = true
    elseif key == "escape" then
        love.event.quit()
    end
end

return menu
