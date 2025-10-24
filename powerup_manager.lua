-- powerup_manager.lua
local PowerupManager = {}
PowerupManager.__index = PowerupManager

function PowerupManager:new()
    local p = { active = {} }
    setmetatable(p, PowerupManager)
    return p
end

function PowerupManager:update(dt)
    -- TODO: handle temporary stat boosts here
end

return PowerupManager

