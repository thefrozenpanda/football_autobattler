-- card_manager.lua
local Card = require("card")

local CardManager = {}
CardManager.__index = CardManager

function CardManager:new(side, phase, cardDefinitions)
    local c = {
        side = side,        -- "player" or "ai"
        phase = phase,      -- "offense" or "defense"
        cards = {}
    }
    setmetatable(c, CardManager)

    -- Create cards from definitions
    if cardDefinitions then
        for _, cardDef in ipairs(cardDefinitions) do
            c:addCard(Card:new(cardDef.position, cardDef.power, cardDef.speed))
        end
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
