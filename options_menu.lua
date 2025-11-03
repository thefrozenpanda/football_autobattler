--- options_menu.lua
--- Options Menu Interface
---
--- Allows players to configure game settings including resolution and display mode.
--- Supports both main menu and pause menu contexts.
---
--- Dependencies: dropdown.lua, settings_manager.lua, ui_scale.lua
--- Used by: main.lua

local options = {}

-- Dependencies
local Dropdown = require("dropdown")
local SettingsManager = require("settings_manager")
local UIScale = require("ui_scale")

-- State
local resolutionDropdown
local displayModeDropdown
local currentSettings
local pendingSettings
local returnContext = "menu"  -- "menu" or "pause"
options.backRequested = false
options.needsReload = false  -- Flag to indicate UI needs reloading after settings change

-- UI Configuration
local titleFont
local labelFont
local buttonFont

local buttonWidth = 200
local buttonHeight = 50
local buttonY = 650
local buttonSpacing = 220

--- Initializes the options menu
--- @param context string Context to return to: "menu" or "pause"
function options.load(context)
    returnContext = context or "menu"
    options.backRequested = false
    options.needsReload = false

    -- Load current settings
    currentSettings = SettingsManager.get()
    pendingSettings = {
        resolution = {
            width = currentSettings.resolution.width,
            height = currentSettings.resolution.height
        },
        displayMode = currentSettings.displayMode,
        version = currentSettings.version
    }

    -- Create fonts
    titleFont = love.graphics.newFont(UIScale.scaleFontSize(42))
    labelFont = love.graphics.newFont(UIScale.scaleFontSize(24))
    buttonFont = love.graphics.newFont(UIScale.scaleFontSize(22))

    -- Get available options
    local resolutions = SettingsManager.getSupportedResolutions()
    local displayModes = SettingsManager.getDisplayModes()

    -- Convert resolutions to dropdown format
    local resolutionOptions = {}
    for _, res in ipairs(resolutions) do
        table.insert(resolutionOptions, {
            value = {width = res.width, height = res.height},
            label = res.label
        })
    end

    -- Find current resolution value for comparison
    local currentResValue = nil
    for _, opt in ipairs(resolutionOptions) do
        if opt.value.width == pendingSettings.resolution.width and
           opt.value.height == pendingSettings.resolution.height then
            currentResValue = opt.value
            break
        end
    end

    -- Create dropdowns (positioned horizontally side-by-side)
    local dropdownWidth = UIScale.scaleWidth(350)
    local dropdownSpacing = UIScale.scaleWidth(40)
    local totalWidth = dropdownWidth * 2 + dropdownSpacing
    local startX = UIScale.centerX(totalWidth)

    local resolutionX = startX
    local displayModeX = startX + dropdownWidth + dropdownSpacing
    local dropdownY = UIScale.scaleY(320)

    resolutionDropdown = Dropdown.new(
        resolutionX,
        dropdownY,
        dropdownWidth,
        resolutionOptions,
        currentResValue
    )

    displayModeDropdown = Dropdown.new(
        displayModeX,
        dropdownY,
        dropdownWidth,
        displayModes,
        pendingSettings.displayMode
    )
end

--- Updates options menu logic
--- @param dt number Delta time
function options.update(dt)
    -- Nothing to update currently
end

--- Renders the options menu
function options.draw()
    -- Clear screen
    love.graphics.clear(0.1, 0.15, 0.25, 1)

    -- Draw title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Options", 0, UIScale.scaleY(100), UIScale.getWidth(), "center")

    -- Draw labels above dropdowns
    love.graphics.setFont(labelFont)
    love.graphics.setColor(0.9, 0.9, 0.9)

    -- Calculate dropdown positions (same as in load function)
    local dropdownWidth = UIScale.scaleWidth(350)
    local dropdownSpacing = UIScale.scaleWidth(40)
    local totalWidth = dropdownWidth * 2 + dropdownSpacing
    local startX = UIScale.centerX(totalWidth)

    local resolutionX = startX
    local displayModeX = startX + dropdownWidth + dropdownSpacing
    local labelY = UIScale.scaleY(280)

    -- Center labels above each dropdown
    local resLabel = "Resolution:"
    local resLabelWidth = labelFont:getWidth(resLabel)
    love.graphics.print(resLabel, resolutionX + (dropdownWidth - resLabelWidth) / 2, labelY)

    local dispLabel = "Display Mode:"
    local dispLabelWidth = labelFont:getWidth(dispLabel)
    love.graphics.print(dispLabel, displayModeX + (dropdownWidth - dispLabelWidth) / 2, labelY)

    -- Draw dropdowns
    resolutionDropdown:draw()
    displayModeDropdown:draw()

    -- Draw buttons
    options.drawButtons()
end

--- Draws Apply and Back buttons
function options.drawButtons()
    love.graphics.setFont(buttonFont)

    local scaledButtonWidth = UIScale.scaleWidth(buttonWidth)
    local scaledButtonHeight = UIScale.scaleHeight(buttonHeight)
    local scaledButtonY = UIScale.scaleY(buttonY)

    -- Calculate button positions (centered with spacing)
    local totalWidth = scaledButtonWidth * 2 + UIScale.scaleWidth(20)
    local startX = UIScale.centerX(totalWidth)

    local applyButtonX = startX
    local backButtonX = startX + scaledButtonWidth + UIScale.scaleWidth(20)

    -- Get mouse position for hover detection
    local mx, my = love.mouse.getPosition()

    -- Apply button
    local applyHovered = mx >= applyButtonX and mx <= applyButtonX + scaledButtonWidth and
                         my >= scaledButtonY and my <= scaledButtonY + scaledButtonHeight

    if applyHovered then
        love.graphics.setColor(0.3, 0.6, 0.3, 0.8)
    else
        love.graphics.setColor(0.2, 0.4, 0.2, 0.6)
    end
    love.graphics.rectangle("fill", applyButtonX, scaledButtonY, scaledButtonWidth, scaledButtonHeight, 10, 10)

    if applyHovered then
        love.graphics.setColor(0.5, 0.8, 0.5)
        love.graphics.setLineWidth(3)
    else
        love.graphics.setColor(0.4, 0.6, 0.4)
        love.graphics.setLineWidth(2)
    end
    love.graphics.rectangle("line", applyButtonX, scaledButtonY, scaledButtonWidth, scaledButtonHeight, 10, 10)

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Apply", applyButtonX, scaledButtonY + UIScale.scaleHeight(12), scaledButtonWidth, "center")

    -- Back button
    local backHovered = mx >= backButtonX and mx <= backButtonX + scaledButtonWidth and
                        my >= scaledButtonY and my <= scaledButtonY + scaledButtonHeight

    if backHovered then
        love.graphics.setColor(0.3, 0.5, 0.7, 0.8)
    else
        love.graphics.setColor(0.2, 0.3, 0.4, 0.6)
    end
    love.graphics.rectangle("fill", backButtonX, scaledButtonY, scaledButtonWidth, scaledButtonHeight, 10, 10)

    if backHovered then
        love.graphics.setColor(0.5, 0.7, 1.0)
        love.graphics.setLineWidth(3)
    else
        love.graphics.setColor(0.4, 0.5, 0.6)
        love.graphics.setLineWidth(2)
    end
    love.graphics.rectangle("line", backButtonX, scaledButtonY, scaledButtonWidth, scaledButtonHeight, 10, 10)

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Back", backButtonX, scaledButtonY + UIScale.scaleHeight(12), scaledButtonWidth, "center")
end

--- Handles keyboard input
--- @param key string The key that was pressed
function options.keypressed(key)
    if key == "escape" then
        options.backRequested = true
    end
end

--- Handles mouse button clicks
--- @param x number Mouse X position
--- @param y number Mouse Y position
--- @param button number Mouse button
function options.mousepressed(x, y, button)
    if button == 1 then
        -- Check dropdowns first
        if resolutionDropdown:mousepressed(x, y) then
            -- Close other dropdown
            displayModeDropdown:close()
            return
        end

        if displayModeDropdown:mousepressed(x, y) then
            -- Close other dropdown
            resolutionDropdown:close()
            return
        end

        -- Check buttons
        local scaledButtonWidth = UIScale.scaleWidth(buttonWidth)
        local scaledButtonHeight = UIScale.scaleHeight(buttonHeight)
        local scaledButtonY = UIScale.scaleY(buttonY)

        local totalWidth = scaledButtonWidth * 2 + UIScale.scaleWidth(20)
        local startX = UIScale.centerX(totalWidth)

        local applyButtonX = startX
        local backButtonX = startX + scaledButtonWidth + UIScale.scaleWidth(20)

        -- Apply button
        if x >= applyButtonX and x <= applyButtonX + scaledButtonWidth and
           y >= scaledButtonY and y <= scaledButtonY + scaledButtonHeight then
            options.applySettings()
            return
        end

        -- Back button
        if x >= backButtonX and x <= backButtonX + scaledButtonWidth and
           y >= scaledButtonY and y <= scaledButtonY + scaledButtonHeight then
            options.backRequested = true
            return
        end

        -- Click outside dropdowns - close them
        if resolutionDropdown:isDropdownOpen() then
            resolutionDropdown:close()
        end
        if displayModeDropdown:isDropdownOpen() then
            displayModeDropdown:close()
        end
    end
end

--- Handles mouse movement
--- @param x number Mouse X position
--- @param y number Mouse Y position
function options.mousemoved(x, y)
    resolutionDropdown:mousemoved(x, y)
    displayModeDropdown:mousemoved(x, y)
end

--- Applies the selected settings
function options.applySettings()
    -- Get selected values from dropdowns
    local selectedResolution = resolutionDropdown:getSelected().value
    local selectedDisplayMode = displayModeDropdown:getSelected().value

    -- Update pending settings
    pendingSettings.resolution.width = selectedResolution.width
    pendingSettings.resolution.height = selectedResolution.height
    pendingSettings.displayMode = selectedDisplayMode

    -- Apply settings
    SettingsManager.apply(pendingSettings)

    -- Save settings to file
    SettingsManager.save(pendingSettings)

    -- Update UI scale for new resolution
    UIScale.update()

    -- Set flag to reload UI
    options.needsReload = true

    -- Go back after applying
    options.backRequested = true
end

--- Gets the return context
--- @return string Return context ("menu" or "pause")
function options.getReturnContext()
    return returnContext
end

return options
