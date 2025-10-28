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
            local card = Card:new(cardDef.position, cardDef.cardType, cardDef.stats)
            c:addCard(card)
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

function CardManager:getYardGenerators()
    local generators = {}
    for _, card in ipairs(self.cards) do
        if card.cardType == Card.TYPE.YARD_GENERATOR then
            table.insert(generators, card)
        end
    end
    return generators
end

function CardManager:getBoosters()
    local boosters = {}
    for _, card in ipairs(self.cards) do
        if card.cardType == Card.TYPE.BOOSTER then
            table.insert(boosters, card)
        end
    end
    return boosters
end

function CardManager:getDefenders()
    local defenders = {}
    for _, card in ipairs(self.cards) do
        if card.cardType == Card.TYPE.DEFENDER then
            table.insert(defenders, card)
        end
    end
    return defenders
end

-- Find cards by position (for targeting)
function CardManager:getCardsByPosition(positions)
    local found = {}
    for _, card in ipairs(self.cards) do
        for _, pos in ipairs(positions) do
            if card.position == pos then
                table.insert(found, card)
                break
            end
        end
    end
    return found
end

return CardManager
