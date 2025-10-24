-- field_state.lua
local FieldState = {}
FieldState.__index = FieldState

function FieldState:new()
    local f = { yards = 0, down = 1 }
    setmetatable(f, FieldState)
    return f
end

function FieldState:update(yardDelta, dt)
    self.yards = self.yards + yardDelta
    if self.yards >= 10 then
        self.yards = self.yards - 10
        self.down = 1
    end
end

function FieldState:hasTouchdown()
    return self.yards >= 100
end

function FieldState:isTurnover()
    return self.down > 4
end

function FieldState:draw()
    love.graphics.print("Yards: " .. math.floor(self.yards), 200, 20)
    love.graphics.print("Down: " .. self.down, 200, 40)
end

return FieldState

