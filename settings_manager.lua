--- settings_manager.lua
--- Settings Persistence System
---
--- Manages game settings including resolution, display mode, and other preferences.
--- Saves settings to disk using LÖVE's filesystem API and loads them on startup.
---
--- Dependencies: None (uses only LÖVE2D filesystem)
--- Used by: main.lua, options_menu.lua

local SettingsManager = {}

-- Default settings
local DEFAULT_SETTINGS = {
    resolution = {width = 1600, height = 900},
    displayMode = "windowed",  -- "windowed", "borderless", "fullscreen"
    version = 1  -- Settings file version for future compatibility
}

-- Current settings (loaded from file or defaults)
local currentSettings = nil

-- Settings file path
local SETTINGS_FILE = "settings.lua"

--- Loads settings from file or returns defaults
--- @return table Settings table
function SettingsManager.load()
    local info = love.filesystem.getInfo(SETTINGS_FILE)

    if info then
        -- File exists, try to load it
        local success, chunk = pcall(love.filesystem.load, SETTINGS_FILE)

        if success and chunk then
            local loadedSettings = chunk()

            -- Validate loaded settings
            if loadedSettings and type(loadedSettings) == "table" then
                -- Merge with defaults to ensure all fields exist
                currentSettings = {}
                for k, v in pairs(DEFAULT_SETTINGS) do
                    if loadedSettings[k] ~= nil then
                        currentSettings[k] = loadedSettings[k]
                    else
                        currentSettings[k] = v
                    end
                end

                return currentSettings
            end
        end
    end

    -- Return defaults if file doesn't exist or failed to load
    currentSettings = {}
    for k, v in pairs(DEFAULT_SETTINGS) do
        currentSettings[k] = v
    end

    return currentSettings
end

--- Saves current settings to file
--- @param settings table Settings table to save
--- @return boolean Success status
function SettingsManager.save(settings)
    currentSettings = settings

    -- Convert settings table to Lua code
    local content = "return {\n"
    content = content .. "    resolution = {width = " .. settings.resolution.width .. ", height = " .. settings.resolution.height .. "},\n"
    content = content .. "    displayMode = \"" .. settings.displayMode .. "\",\n"
    content = content .. "    version = " .. (settings.version or DEFAULT_SETTINGS.version) .. "\n"
    content = content .. "}\n"

    -- Write to file
    local success = love.filesystem.write(SETTINGS_FILE, content)

    return success
end

--- Gets current settings
--- @return table Current settings
function SettingsManager.get()
    if not currentSettings then
        return SettingsManager.load()
    end
    return currentSettings
end

--- Gets default settings
--- @return table Default settings
function SettingsManager.getDefaults()
    local defaults = {}
    for k, v in pairs(DEFAULT_SETTINGS) do
        defaults[k] = v
    end
    return defaults
end

--- Applies settings to the game window
--- @param settings table Settings to apply
function SettingsManager.apply(settings)
    local width = settings.resolution.width
    local height = settings.resolution.height
    local mode = settings.displayMode

    local flags = {
        resizable = false,
        borderless = (mode == "borderless"),
        fullscreen = (mode == "fullscreen"),
        fullscreentype = (mode == "fullscreen") and "exclusive" or "desktop",
        vsync = 1
    }

    love.window.setMode(width, height, flags)

    -- Update current settings
    currentSettings = settings
end

--- Gets list of supported 16:9 resolutions >= 1280x720 based on monitor
--- @return table Array of resolution tables with width, height, and label
function SettingsManager.getSupportedResolutions()
    -- Get all fullscreen modes
    local modes = love.window.getFullscreenModes()
    local resolutions = {}
    local seen = {}  -- Track unique resolutions

    -- Common 16:9 resolutions to check
    local common169 = {
        {width = 1280, height = 720, label = "1280x720 (HD)"},
        {width = 1600, height = 900, label = "1600x900 (HD+)"},
        {width = 1920, height = 1080, label = "1920x1080 (Full HD)"},
        {width = 2560, height = 1440, label = "2560x1440 (2K)"},
        {width = 3840, height = 2160, label = "3840x2160 (4K)"},
    }

    -- Check each common resolution against available modes
    for _, res in ipairs(common169) do
        if res.width >= 1280 and res.height >= 720 then
            -- Check if this resolution is supported
            for _, mode in ipairs(modes) do
                if mode.width == res.width and mode.height == res.height then
                    local key = res.width .. "x" .. res.height
                    if not seen[key] then
                        table.insert(resolutions, {
                            width = res.width,
                            height = res.height,
                            label = res.label
                        })
                        seen[key] = true
                    end
                    break
                end
            end
        end
    end

    -- If no resolutions found (shouldn't happen), add defaults
    if #resolutions == 0 then
        table.insert(resolutions, {
            width = 1280,
            height = 720,
            label = "1280x720 (HD)"
        })
        table.insert(resolutions, {
            width = 1600,
            height = 900,
            label = "1600x900 (HD+)"
        })
    end

    -- Sort by resolution (lowest to highest)
    table.sort(resolutions, function(a, b)
        return a.width < b.width
    end)

    return resolutions
end

--- Gets display mode options
--- @return table Array of display mode tables with value and label
function SettingsManager.getDisplayModes()
    return {
        {value = "windowed", label = "Windowed"},
        {value = "borderless", label = "Borderless Fullscreen"},
        {value = "fullscreen", label = "Fullscreen"}
    }
end

return SettingsManager
