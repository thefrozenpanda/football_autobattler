-- card.lua
local Card = {}
Card.__index = Card

function Card:new(name, power, speed)
    local c = {
        name = name or "Unknown",
        power = power or 100,
        speed = speed or 1.5,
        cooldown = 1 / (speed or 1.5),
        timer = 0
    }
    setmetatable(c, Card)
    return c
end

function Card:update(dt)
    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.timer = self.cooldown
        return self:act()
    end
    return 0
end

function Card:act()
    local rng = 0.9 + math.random() * 0.2
    return self.power * rng * 0.01
end

return Card

