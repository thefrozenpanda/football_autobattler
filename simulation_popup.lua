--- simulation_popup.lua
--- AI Match Simulation Loading Popup
---
--- Displays a loading message while AI vs AI matches are being simulated.
--- Shows "Simulating remaining games..." in a centered modal window.
---
--- Dependencies: ui_scale.lua
--- Used by: main.lua
--- LÖVE Callbacks: love.draw

local SimulationPopup = {}
local UIScale = require("ui_scale")

SimulationPopup.active = false
SimulationPopup.message = "Simulating remaining games..."

-- UI configuration (base values for 1600x900)
local POPUP_WIDTH = 500
local POPUP_HEIGHT = 150

-- Font
local messageFont

--- Initializes the simulation popup
function SimulationPopup.init()
    UIScale.update()
    messageFont = love.graphics.newFont(UIScale.scaleFontSize(28))
end

--- Shows the simulation popup
function SimulationPopup.show()
    SimulationPopup.active = true
end

--- Hides the simulation popup
function SimulationPopup.hide()
    SimulationPopup.active = false
end

--- Checks if popup is active
--- @return boolean True if popup is showing
function SimulationPopup.isActive()
    return SimulationPopup.active
end

--- LÖVE Callback: Draw UI
function SimulationPopup.draw()
    if not SimulationPopup.active then
        return
    end

    -- Initialize font if needed
    if not messageFont then
        SimulationPopup.init()
    end

    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, UIScale.getWidth(), UIScale.getHeight())

    -- Popup window
    local scaledPopupWidth = UIScale.scaleWidth(POPUP_WIDTH)
    local scaledPopupHeight = UIScale.scaleHeight(POPUP_HEIGHT)
    local popupX = UIScale.centerX(scaledPopupWidth)
    local popupY = UIScale.centerY(scaledPopupHeight)

    love.graphics.setColor(0.15, 0.15, 0.2)
    love.graphics.rectangle("fill", popupX, popupY, scaledPopupWidth, scaledPopupHeight)

    -- Border
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.setLineWidth(UIScale.scaleUniform(3))
    love.graphics.rectangle("line", popupX, popupY, scaledPopupWidth, scaledPopupHeight)

    -- Message text
    love.graphics.setFont(messageFont)
    love.graphics.setColor(1, 1, 1)
    local textWidth = messageFont:getWidth(SimulationPopup.message)
    love.graphics.print(SimulationPopup.message, popupX + (scaledPopupWidth - textWidth) / 2, popupY + UIScale.scaleHeight(60))
end

return SimulationPopup
