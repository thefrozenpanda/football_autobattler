--- conf.lua
--- LÖVE2D Configuration File
---
--- This file configures the LÖVE game engine settings for The Gridiron Bazaar.
--- It sets window properties, enabled modules, and various engine behaviors.
---
--- Dependencies: None (LÖVE2D framework only)
--- Used by: LÖVE2D engine on startup
--- LÖVE Callbacks: love.conf

--- Configures LÖVE2D engine settings
--- @param t table The configuration table provided by LÖVE
function love.conf(t)
    -- Application Settings
    t.identity = "football_autobattler"    -- Save directory name (was nil, now set for proper save location)
    t.appendidentity = false                -- Search files in source directory before save directory
    t.version = "11.3"                      -- Target LÖVE version
    t.console = false                       -- Attach a console (Windows only) - set true for debugging
    t.accelerometerjoystick = true          -- Enable accelerometer on mobile devices
    t.externalstorage = false               -- Use external storage on Android
    t.gammacorrect = false                  -- Gamma-correct rendering

    -- Audio Settings
    t.audio.mic = false                     -- Microphone capabilities (Android)
    t.audio.mixwithsystem = true            -- Keep background music playing (iOS/Android)

    -- Window Configuration
    t.window.title = "The Gridiron Bazaar" -- Window title
    t.window.icon = nil                     -- Window icon (none set)
    t.window.width = 1600                   -- Window width in pixels
    t.window.height = 900                   -- Window height in pixels
    t.window.borderless = false             -- Windowed mode with borders
    t.window.resizable = false              -- Fixed window size
    t.window.minwidth = 1                   -- Minimum width if resizable
    t.window.minheight = 1                  -- Minimum height if resizable
    t.window.fullscreen = false             -- Windowed mode by default
    t.window.fullscreentype = "desktop"     -- Desktop fullscreen mode
    t.window.vsync = 1                      -- Enable vertical sync (prevent tearing)
    t.window.msaa = 0                       -- Multi-sampled antialiasing samples
    t.window.depth = nil                    -- Depth buffer bits
    t.window.stencil = nil                  -- Stencil buffer bits
    t.window.display = 1                    -- Primary monitor
    t.window.highdpi = false                -- High-DPI support (Retina displays)
    t.window.usedpiscale = true             -- Automatic DPI scaling
    t.window.x = nil                        -- Window X position (centered)
    t.window.y = nil                        -- Window Y position (centered)

    -- Module Configuration
    -- NOTE: Some unused modules could be disabled for minor performance gain
    t.modules.audio = true                  -- Audio module (music/sound effects)
    t.modules.data = true                   -- Data module (encoding/compression)
    t.modules.event = true                  -- Event module (required)
    t.modules.font = true                   -- Font module (required for text)
    t.modules.graphics = true               -- Graphics module (required)
    t.modules.image = true                  -- Image module (required)
    t.modules.joystick = true               -- Joystick module (not currently used)
    t.modules.keyboard = true               -- Keyboard module (required)
    t.modules.math = true                   -- Math module (required)
    t.modules.mouse = true                  -- Mouse module (required)
    t.modules.physics = true                -- Physics module (not currently used)
    t.modules.sound = true                  -- Sound module (audio playback)
    t.modules.system = true                 -- System module (OS information)
    t.modules.thread = true                 -- Threading module (not currently used)
    t.modules.timer = true                  -- Timer module (required for dt)
    t.modules.touch = true                  -- Touch module (mobile support)
    t.modules.video = true                  -- Video module (not currently used)
    t.modules.window = true                 -- Window module (required)
end
