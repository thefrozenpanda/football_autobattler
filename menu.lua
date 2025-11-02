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
local UIScale = require("ui_scale")
local flux = require("lib.flux")

-- Public State
menu.startGameRequested = false     -- Flag set when player clicks "Start Game"
menu.continueSeasonRequested = false  -- Flag set when player clicks "Continue Season"
menu.optionsRequested = false       -- Flag set when player clicks "Options"

-- UI Configuration
local titleFont
local menuFont
local copyrightFont
local selectedOption = 1          -- Currently selected menu option (1-based index)
local menuOptions = {"Start New Season", "Continue Season", "Options", "Exit Game"}
local buttonWidth = 300
local buttonHeight = 60
local buttonY = {400, 510, 620, 730}   -- Y positions for each button

-- Animation state
local menuAnimState = {opacity = 1.0}

--- Initializes the menu
--- Creates fonts and resets menu state. Called when entering menu from other states.
function menu.load()
    -- Update UI scale
    UIScale.update()

    -- Create fonts for different text elements (scaled)
    titleFont = love.graphics.newFont(UIScale.scaleFontSize(48))
    menuFont = love.graphics.newFont(UIScale.scaleFontSize(28))
    copyrightFont = love.graphics.newFont(UIScale.scaleFontSize(18))

    -- Reset menu state
    selectedOption = 1
    menu.startGameRequested = false
    menu.continueSeasonRequested = false
    menu.optionsRequested = false

    -- Fade in animation
    menuAnimState.opacity = 0
    flux.to(menuAnimState, 0.5, {opacity = 1}):ease("quadout")
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

    -- Apply fade animation
    love.graphics.push()
    love.graphics.setColor(1, 1, 1, menuAnimState.opacity)

    -- Scale button dimensions
    local scaledButtonWidth = UIScale.scaleWidth(buttonWidth)
    local scaledButtonHeight = UIScale.scaleHeight(buttonHeight)

    -- Draw game title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1, menuAnimState.opacity)
    love.graphics.printf("The Gridiron Bazaar", 0, UIScale.scaleY(350), UIScale.getWidth(), "center")

    -- Draw subtitle (if you have one in the future)

    -- Check if save exists
    local hasSave = SeasonManager.saveExists()

    -- Draw menu buttons
    love.graphics.setFont(menuFont)
    for i, option in ipairs(menuOptions) do
        local x = UIScale.centerX(scaledButtonWidth)
        local y = UIScale.scaleY(buttonY[i])

        -- Check if this option is disabled
        local isDisabled = (i == 2 and not hasSave)  -- Continue Season disabled if no save

        -- Draw button background (highlighted if selected)
        if isDisabled then
            love.graphics.setColor(0.15, 0.15, 0.2, 0.4 * menuAnimState.opacity)  -- Very dark/grayed out
        elseif i == selectedOption then
            love.graphics.setColor(0.3, 0.5, 0.7, 0.8 * menuAnimState.opacity)  -- Bright blue when selected
        else
            love.graphics.setColor(0.2, 0.3, 0.4, 0.6 * menuAnimState.opacity)  -- Dark gray when not selected
        end
        love.graphics.rectangle("fill", x, y, scaledButtonWidth, scaledButtonHeight, 10, 10)

        -- Draw button border (thicker if selected)
        if isDisabled then
            love.graphics.setColor(0.3, 0.3, 0.35, menuAnimState.opacity)
            love.graphics.setLineWidth(UIScale.scaleUniform(2))
        elseif i == selectedOption then
            love.graphics.setColor(0.5, 0.7, 1.0, menuAnimState.opacity)
            love.graphics.setLineWidth(UIScale.scaleUniform(3))
        else
            love.graphics.setColor(0.4, 0.5, 0.6, menuAnimState.opacity)
            love.graphics.setLineWidth(UIScale.scaleUniform(2))
        end
        love.graphics.rectangle("line", x, y, scaledButtonWidth, scaledButtonHeight, 10, 10)

        -- Draw button text
        if isDisabled then
            love.graphics.setColor(0.4, 0.4, 0.45, menuAnimState.opacity)  -- Grayed out text
        else
            love.graphics.setColor(1, 1, 1, menuAnimState.opacity)
        end
        love.graphics.printf(option, x, y + UIScale.scaleHeight(15), scaledButtonWidth, "center")

        -- Draw save info under "Continue Season" button (option 2)
        if i == 2 then
            love.graphics.setFont(copyrightFont)
            if hasSave then
                local saveInfo = SeasonManager.getSaveInfo()
                if saveInfo then
                    love.graphics.setColor(0.8, 0.8, 0.8, menuAnimState.opacity)
                    local infoText = string.format("%s (%d-%d) - Week %d",
                        saveInfo.teamName, saveInfo.wins, saveInfo.losses, saveInfo.week)
                    love.graphics.printf(infoText, x, y + scaledButtonHeight + UIScale.scaleHeight(5), scaledButtonWidth, "center")
                end
            else
                love.graphics.setColor(0.5, 0.5, 0.5, menuAnimState.opacity)
                love.graphics.printf("No Current Save", x, y + scaledButtonHeight + UIScale.scaleHeight(5), scaledButtonWidth, "center")
            end
            love.graphics.setFont(menuFont)  -- Reset font
        end
    end

    -- Draw instructions and copyright
    love.graphics.setFont(copyrightFont)
    love.graphics.setColor(0.6, 0.6, 0.6, menuAnimState.opacity)
    love.graphics.printf("Use Arrow Keys or Mouse to Navigate - Enter or Click to Select", 0, UIScale.scaleY(820), UIScale.getWidth(), "center")
    love.graphics.printf("© 2025 The Gridiron Bazaar", 0, UIScale.scaleY(860), UIScale.getWidth(), "center")

    love.graphics.pop()
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
        local scaledButtonWidth = UIScale.scaleWidth(buttonWidth)
        local scaledButtonHeight = UIScale.scaleHeight(buttonHeight)
        local buttonX = UIScale.centerX(scaledButtonWidth)

        -- Check each button for collision
        for i = 1, #menuOptions do
            local buttonYPos = UIScale.scaleY(buttonY[i])
            if x >= buttonX and x <= buttonX + scaledButtonWidth and
               y >= buttonYPos and y <= buttonYPos + scaledButtonHeight then
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
    local scaledButtonWidth = UIScale.scaleWidth(buttonWidth)
    local scaledButtonHeight = UIScale.scaleHeight(buttonHeight)
    local buttonX = UIScale.centerX(scaledButtonWidth)
    selectedOption = 0  -- No selection by default (no highlight)

    -- Check if mouse is over any button
    for i = 1, #menuOptions do
        local buttonYPos = UIScale.scaleY(buttonY[i])
        if x >= buttonX and x <= buttonX + scaledButtonWidth and
           y >= buttonYPos and y <= buttonYPos + scaledButtonHeight then
            selectedOption = i
            break
        end
    end
end

--- Executes the selected menu option
--- Option 1: Start New Season
--- Option 2: Continue Season
--- Option 3: Options
--- Option 4: Exit Game
--- @param option number The menu option index (1-4)
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
        -- Options
        menu.optionsRequested = true
    elseif option == 4 then
        -- Exit Game
        love.event.quit()
    end
end

return menu
