-- card_manager.lua
local Card = require("card")

local CardManager = {}
CardManager.__index = CardManager

function CardManager:new(side, phase)
    local c = {
        side = side,        -- "player" or "ai"
        phase = phase,      -- "offense" or "defense"
        cards = {}
    }
    setmetatable(c, CardManager)

    -- Create position-specific cards
    if phase == "offense" then
        c:addCard(Card:new("QB", 130, 1.8))
        c:addCard(Card:new("RB", 110, 2.2))
        c:addCard(Card:new("WR", 100, 2.5))
        c:addCard(Card:new("WR", 100, 2.5))
    else -- defense
        c:addCard(Card:new("LB", 120, 2.0))
        c:addCard(Card:new("CB", 105, 2.3))
        c:addCard(Card:new("CB", 105, 2.3))
        c:addCard(Card:new("S", 115, 1.9))
    end

    return c
end

function CardManager:addCard(card)
    table.insert(self.cards, card)
end

function CardManager:update(dt)
    for _, card in ipairs(self.cards) do
        card:update(dt)
    end
end

function CardManager:getTotalPower()
    local total = 0
    for _, card in ipairs(self.cards) do
        total = total + card.power
    end
    return total
end

return CardManager

