-- menu.lua
local menu = {}

menu.startGameRequested = false
local titleFont
local menuFont
local copyrightFont
local selectedOption = 1
local menuOptions = {"Start Game", "Exit Game"}
local buttonWidth = 300
local buttonHeight = 60
local buttonY = {350, 440}

function menu.load()
    titleFont = love.graphics.newFont(48)
    menuFont = love.graphics.newFont(28)
    copyrightFont = love.graphics.newFont(18)
    selectedOption = 1
    menu.startGameRequested = false
end

function menu.update(dt)
    -- Menu is static, no updates needed
end

function menu.draw()
    -- Clear screen with background color
    love.graphics.clear(0.1, 0.15, 0.25, 1)

    -- Draw title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("The Gridiron Bazaar", 0, 250, 1600, "center")

    -- Draw menu options
    love.graphics.setFont(menuFont)
    for i, option in ipairs(menuOptions) do
        local x = (1600 - buttonWidth) / 2
        local y = buttonY[i]

        -- Draw button background
        if i == selectedOption then
            love.graphics.setColor(0.3, 0.5, 0.7, 0.8)
        else
            love.graphics.setColor(0.2, 0.3, 0.4, 0.6)
        end
        love.graphics.rectangle("fill", x, y, buttonWidth, buttonHeight, 10, 10)

        -- Draw button border
        if i == selectedOption then
            love.graphics.setColor(0.5, 0.7, 1.0)
            love.graphics.setLineWidth(3)
        else
            love.graphics.setColor(0.4, 0.5, 0.6)
            love.graphics.setLineWidth(2)
        end
        love.graphics.rectangle("line", x, y, buttonWidth, buttonHeight, 10, 10)

        -- Draw button text
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(option, x, y + 15, buttonWidth, "center")
    end

    -- Draw copyright
    love.graphics.setFont(copyrightFont)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.printf("Use Arrow Keys or Mouse to Navigate - Enter or Click to Select", 0, 810, 1600, "center")
    love.graphics.printf("© 2025 Your Studio Name", 0, 850, 1600, "center")
end

function menu.keypressed(key)
    if key == "up" then
        selectedOption = selectedOption - 1
        if selectedOption < 1 then
            selectedOption = #menuOptions
        end
    elseif key == "down" then
        selectedOption = selectedOption + 1
        if selectedOption > #menuOptions then
            selectedOption = 1
        end
    elseif key == "return" or key == "space" then
        menu.selectOption(selectedOption)
    elseif key == "escape" then
        love.event.quit()
    end
end

function menu.mousepressed(x, y, button)
    if button == 1 then
        local buttonX = (1600 - buttonWidth) / 2
        for i = 1, #menuOptions do
            local buttonYPos = buttonY[i]
            if x >= buttonX and x <= buttonX + buttonWidth and
               y >= buttonYPos and y <= buttonYPos + buttonHeight then
                menu.selectOption(i)
                break
            end
        end
    end
end

function menu.mousemoved(x, y)
    local buttonX = (1600 - buttonWidth) / 2
    for i = 1, #menuOptions do
        local buttonYPos = buttonY[i]
        if x >= buttonX and x <= buttonX + buttonWidth and
           y >= buttonYPos and y <= buttonYPos + buttonHeight then
            selectedOption = i
            break
        end
    end
end

function menu.selectOption(option)
    if option == 1 then
        -- Start Game
        menu.startGameRequested = true
    elseif option == 2 then
        -- Exit Game
        love.event.quit()
    end
end

return menu
