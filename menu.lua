--- menu.lua
--- Main Menu Interface
---
--- Displays the game's main menu with "Start Game" and "Exit Game" options.
--- Supports both keyboard navigation (arrow keys + Enter) and mouse controls.
--- Manages the menu state and signals to main.lua when the player wants to start.
---
--- Dependencies: None (uses only LÖVE2D graphics/input)
--- Used by: main.lua
--- LÖVE Callbacks: None (uses menu-specific functions)

local menu = {}

-- Dependencies
local SeasonManager = require("season_manager")

-- Public State
menu.startGameRequested = false     -- Flag set when player clicks "Start Game"
menu.continueSeasonRequested = false  -- Flag set when player clicks "Continue Season"

-- UI Configuration
local titleFont
local menuFont
local copyrightFont
local selectedOption = 1          -- Currently selected menu option (1-based index)
local menuOptions = {"Start New Season", "Continue Season", "Exit Game"}
local buttonWidth = 300
local buttonHeight = 60
local buttonY = {450, 580, 710}   -- Y positions for each button

--- Initializes the menu
--- Creates fonts and resets menu state. Called when entering menu from other states.
function menu.load()
    -- Create fonts for different text elements
    titleFont = love.graphics.newFont(48)
    menuFont = love.graphics.newFont(28)
    copyrightFont = love.graphics.newFont(18)

    -- Reset menu state
    selectedOption = 1
    menu.startGameRequested = false
    menu.continueSeasonRequested = false
end

--- Updates menu logic
--- Currently no-op as menu is static. Kept for consistency with other modules.
--- @param dt number Delta time in seconds (unused)
function menu.update(dt)
    -- Menu is static, no updates needed
end

--- Renders the main menu
--- Draws title, menu buttons with hover/select states, and instructions.
function menu.draw()
    -- Clear screen with dark blue background
    love.graphics.clear(0.1, 0.15, 0.25, 1)

    -- Draw game title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("The Gridiron Bazaar", 0, 350, 1600, "center")

    -- Check if save exists
    local hasSave = SeasonManager.saveExists()

    -- Draw menu buttons
    love.graphics.setFont(menuFont)
    for i, option in ipairs(menuOptions) do
        local x = (1600 - buttonWidth) / 2
        local y = buttonY[i]

        -- Check if this option is disabled
        local isDisabled = (i == 2 and not hasSave)  -- Continue Season disabled if no save

        -- Draw button background (highlighted if selected)
        if isDisabled then
            love.graphics.setColor(0.15, 0.15, 0.2, 0.4)  -- Very dark/grayed out
        elseif i == selectedOption then
            love.graphics.setColor(0.3, 0.5, 0.7, 0.8)  -- Bright blue when selected
        else
            love.graphics.setColor(0.2, 0.3, 0.4, 0.6)  -- Dark gray when not selected
        end
        love.graphics.rectangle("fill", x, y, buttonWidth, buttonHeight, 10, 10)

        -- Draw button border (thicker if selected)
        if isDisabled then
            love.graphics.setColor(0.3, 0.3, 0.35)
            love.graphics.setLineWidth(2)
        elseif i == selectedOption then
            love.graphics.setColor(0.5, 0.7, 1.0)
            love.graphics.setLineWidth(3)
        else
            love.graphics.setColor(0.4, 0.5, 0.6)
            love.graphics.setLineWidth(2)
        end
        love.graphics.rectangle("line", x, y, buttonWidth, buttonHeight, 10, 10)

        -- Draw button text
        if isDisabled then
            love.graphics.setColor(0.4, 0.4, 0.45)  -- Grayed out text
        else
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.printf(option, x, y + 15, buttonWidth, "center")
    end

    -- Draw instructions and copyright
    love.graphics.setFont(copyrightFont)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.printf("Use Arrow Keys or Mouse to Navigate - Enter or Click to Select", 0, 820, 1600, "center")
    love.graphics.printf("© 2025 The Gridiron Bazaar", 0, 860, 1600, "center")
end

--- Handles keyboard input for menu navigation
--- Arrow keys navigate, Enter/Space selects, ESC quits game
--- @param key string The key that was pressed
function menu.keypressed(key)
    if key == "up" then
        -- Navigate up (wraps to bottom)
        selectedOption = selectedOption - 1
        if selectedOption < 1 then
            selectedOption = #menuOptions
        end
    elseif key == "down" then
        -- Navigate down (wraps to top)
        selectedOption = selectedOption + 1
        if selectedOption > #menuOptions then
            selectedOption = 1
        end
    elseif key == "return" or key == "space" then
        -- Select current option
        menu.selectOption(selectedOption)
    elseif key == "escape" then
        -- Quit game immediately
        love.event.quit()
    end
end

--- Handles mouse button clicks
--- Checks if click is within any menu button bounds and selects that option
--- @param x number Mouse X position in pixels
--- @param y number Mouse Y position in pixels
--- @param button number Mouse button (1=left, 2=right, 3=middle)
function menu.mousepressed(x, y, button)
    if button == 1 then  -- Left click only
        local buttonX = (1600 - buttonWidth) / 2

        -- Check each button for collision
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

--- Handles mouse movement for hover effects
--- Updates selectedOption to highlight button under cursor
--- Sets selectedOption to 0 if mouse is not over any button (no highlight)
--- @param x number Mouse X position in pixels
--- @param y number Mouse Y position in pixels
function menu.mousemoved(x, y)
    local buttonX = (1600 - buttonWidth) / 2
    selectedOption = 0  -- No selection by default (no highlight)

    -- Check if mouse is over any button
    for i = 1, #menuOptions do
        local buttonYPos = buttonY[i]
        if x >= buttonX and x <= buttonX + buttonWidth and
           y >= buttonYPos and y <= buttonYPos + buttonHeight then
            selectedOption = i
            break
        end
    end
end

--- Executes the selected menu option
--- Option 1: Start Game (sets flag for main.lua to detect)
--- Option 2: Exit Game (quits application)
--- @param option number The menu option index (1 or 2)
function menu.selectOption(option)
    if option == 1 then
        -- Start New Season - check for existing save
        if SeasonManager.saveExists() then
            -- Show overwrite warning (for now, just delete and start)
            -- TODO: Add confirmation dialog
            SeasonManager.deleteSave()
        end
        menu.startGameRequested = true
    elseif option == 2 then
        -- Continue Season - only if save exists
        if SeasonManager.saveExists() then
            menu.continueSeasonRequested = true
        end
    elseif option == 3 then
        -- Exit Game
        love.event.quit()
    end
end

return menu
