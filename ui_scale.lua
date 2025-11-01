--- ui_scale.lua
--- UI Scaling System
---
--- Provides scaling utilities to make UI elements scale proportionally
--- based on the current window resolution. Uses 1600x900 as the base resolution.
---
--- Dependencies: None
--- Used by: All UI modules

local UIScale = {}

-- Base resolution (design resolution)
local BASE_WIDTH = 1600
local BASE_HEIGHT = 900

-- Current scale factors
local scaleX = 1.0
local scaleY = 1.0
local uniformScale = 1.0  -- Minimum of scaleX and scaleY for elements that should scale uniformly

--- Updates scale factors based on current window size
function UIScale.update()
    local width, height = love.graphics.getDimensions()

    scaleX = width / BASE_WIDTH
    scaleY = height / BASE_HEIGHT
    uniformScale = math.min(scaleX, scaleY)
end

--- Gets the current X scale factor
--- @return number Scale factor for X axis
function UIScale.getScaleX()
    return scaleX
end

--- Gets the current Y scale factor
--- @return number Scale factor for Y axis
function UIScale.getScaleY()
    return scaleY
end

--- Gets the uniform scale factor (minimum of X and Y)
--- @return number Uniform scale factor
function UIScale.getUniformScale()
    return uniformScale
end

--- Scales an X coordinate
--- @param x number Base X coordinate (at 1600x900)
--- @return number Scaled X coordinate
function UIScale.scaleX(x)
    return x * scaleX
end

--- Scales a Y coordinate
--- @param y number Base Y coordinate (at 1600x900)
--- @return number Scaled Y coordinate
function UIScale.scaleY(y)
    return y * scaleY
end

--- Scales a width value
--- @param w number Base width (at 1600x900)
--- @return number Scaled width
function UIScale.scaleWidth(w)
    return w * scaleX
end

--- Scales a height value
--- @param h number Base height (at 1600x900)
--- @return number Scaled height
function UIScale.scaleHeight(h)
    return h * scaleY
end

--- Scales a value uniformly (using minimum scale factor)
--- Useful for elements that should maintain aspect ratio
--- @param value number Base value
--- @return number Scaled value
function UIScale.scaleUniform(value)
    return value * uniformScale
end

--- Scales a font size
--- @param size number Base font size
--- @return number Scaled font size (rounded to nearest integer)
function UIScale.scaleFontSize(size)
    return math.floor(size * uniformScale + 0.5)
end

--- Gets the current window width
--- @return number Window width
function UIScale.getWidth()
    return love.graphics.getWidth()
end

--- Gets the current window height
--- @return number Window height
function UIScale.getHeight()
    return love.graphics.getHeight()
end

--- Gets the base (design) width
--- @return number Base width (1600)
function UIScale.getBaseWidth()
    return BASE_WIDTH
end

--- Gets the base (design) height
--- @return number Base height (900)
function UIScale.getBaseHeight()
    return BASE_HEIGHT
end

--- Centers an element horizontally
--- @param width number Element width (already scaled)
--- @return number X position to center the element
function UIScale.centerX(width)
    return (UIScale.getWidth() - width) / 2
end

--- Centers an element vertically
--- @param height number Element height (already scaled)
--- @return number Y position to center the element
function UIScale.centerY(height)
    return (UIScale.getHeight() - height) / 2
end

-- Initialize scale on module load
UIScale.update()

return UIScale
