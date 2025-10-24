-- card_manager.lua
local Card = require("card")

local CardManager = {}
CardManager.__index = CardManager

function CardManager:new(side)
    local c = { side = side, cards = {} }
    setmetatable(c, CardManager)
    c:addCard(Card:new("Player1", 120, 2.0))
    c:addCard(Card:new("Player2", 100, 1.5))
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

function CardManager:computeYards(enemy)
    local offensePower, defensePower = 0, 0
    for _, card in ipairs(self.cards) do
        offensePower = offensePower + card:act()
    end
    for _, card in ipairs(enemy.cards) do
        defensePower = defensePower + card:act()
    end
    return offensePower - defensePower
end

return CardManager

