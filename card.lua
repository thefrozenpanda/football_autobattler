-- card.lua
local Card = {}
Card.__index = Card

function Card:new(position, power, speed)
    local c = {
        position = position or "Unknown",
        power = power or 100,
        speed = speed or 1.5,
        cooldown = 1 / (speed or 1.5),
        timer = 0,
        justActed = false,
        actHighlightTimer = 0
    }
    setmetatable(c, Card)
    return c
end

function Card:update(dt)
    -- Update action highlight timer
    if self.actHighlightTimer > 0 then
        self.actHighlightTimer = self.actHighlightTimer - dt
        if self.actHighlightTimer <= 0 then
            self.justActed = false
        end
    end

    -- Update card action timer
    self.timer = self.timer + dt
    if self.timer >= self.cooldown then
        self.timer = 0
        self.justActed = true
        self.actHighlightTimer = 0.2  -- Highlight for 0.2 seconds
        return self:act()
    end
    return 0
end

function Card:act()
    local rng = 0.9 + math.random() * 0.2
    return self.power * rng * 0.01
end

function Card:getProgress()
    return self.timer / self.cooldown
end

return Card

