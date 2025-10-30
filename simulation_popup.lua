--- simulation_popup.lua
--- AI Match Simulation Loading Popup
---
--- Displays a loading message while AI vs AI matches are being simulated.
--- Shows "Simulating remaining games..." in a centered modal window.
---
--- Dependencies: None
--- Used by: main.lua
--- LÖVE Callbacks: love.draw

local SimulationPopup = {}

SimulationPopup.active = false
SimulationPopup.message = "Simulating remaining games..."

-- UI configuration
local POPUP_WIDTH = 500
local POPUP_HEIGHT = 150

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

    local screenWidth = 1600
    local screenHeight = 900

    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Popup window
    local popupX = (screenWidth - POPUP_WIDTH) / 2
    local popupY = (screenHeight - POPUP_HEIGHT) / 2

    love.graphics.setColor(0.15, 0.15, 0.2)
    love.graphics.rectangle("fill", popupX, popupY, POPUP_WIDTH, POPUP_HEIGHT)

    -- Border
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", popupX, popupY, POPUP_WIDTH, POPUP_HEIGHT)

    -- Message text
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.setColor(1, 1, 1)
    local textWidth = love.graphics.getFont():getWidth(SimulationPopup.message)
    love.graphics.print(SimulationPopup.message, popupX + (POPUP_WIDTH - textWidth) / 2, popupY + 60)
end

return SimulationPopup
