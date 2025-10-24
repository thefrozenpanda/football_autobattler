
-- ui.lua
local UI = {}
UI.__index = UI

function UI:new()
    local u = {}
    setmetatable(u, UI)
    return u
end

function UI:draw()
    -- TODO: draw buttons, meters, etc.
end

return UI
