-- card_manager.lua
local Card = require("card")

local CardManager = {}
CardManager.__index = CardManager

-- Debug logger (set by match.lua)
CardManager.logger = nil

function CardManager:new(side, phase, cardDefinitions)
    local c = {
        side = side,        -- "player" or "ai"
        phase = phase,      -- "offense" or "defense"
        cards = {},
        cardCache = {}      -- Cache for filtered card lists by type
    }
    setmetatable(c, CardManager)

    -- Create cards from definitions
    if cardDefinitions then
        for _, cardDef in ipairs(cardDefinitions) do
            local card = Card:new(cardDef.position, cardDef.cardType, cardDef.stats)
            c:addCard(card)

            -- Log card creation
            if CardManager.logger then
                CardManager.logger:logCardCreation(card)
            end
        end
    end

    -- Build cache after all cards are added
    c:buildCache()

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

-- Builds cache of filtered card lists by type for performance
function CardManager:buildCache()
    self.cardCache = {}
    self.cardCache[Card.TYPE.YARD_GENERATOR] = {}
    self.cardCache[Card.TYPE.BOOSTER] = {}
    self.cardCache[Card.TYPE.DEFENDER] = {}

    for _, card in ipairs(self.cards) do
        local cardType = card.cardType
        if self.cardCache[cardType] then
            table.insert(self.cardCache[cardType], card)
        end
    end
end

function CardManager:getYardGenerators()
    return self.cardCache[Card.TYPE.YARD_GENERATOR] or {}
end

function CardManager:getBoosters()
    return self.cardCache[Card.TYPE.BOOSTER] or {}
end

function CardManager:getDefenders()
    return self.cardCache[Card.TYPE.DEFENDER] or {}
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
