-- phase_manager.lua
local CardManager = require("card_manager")
local FieldState = require("field_state")

local PhaseManager = {}
PhaseManager.__index = PhaseManager

function PhaseManager:new(phaseType)
    local p = {
        type = phaseType,
        offense = CardManager:new("offense"),
        defense = CardManager:new("defense"),
        field = FieldState:new(),
        complete = false
    }
    setmetatable(p, PhaseManager)
    return p
end

function PhaseManager:update(dt)
    self.offense:update(dt)
    self.defense:update(dt)

    local yardDelta = self.offense:computeYards(self.defense)
    self.field:update(yardDelta, dt)

    if self.field:hasTouchdown() or self.field:isTurnover() then
        self.complete = true
    end
end

function PhaseManager:isComplete()
    return self.complete
end

function PhaseManager:draw()
    self.field:draw()
end

return PhaseManager

