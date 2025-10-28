-- debug_logger.lua
-- Logging system for troubleshooting gameplay speed issues

local DebugLogger = {}
DebugLogger.__index = DebugLogger

local LOG_FILE = "match_debug.log"
local enabled = true

function DebugLogger:new()
    local d = {
        startTime = love.timer.getTime(),
        logBuffer = {},
        frameCount = 0
    }
    setmetatable(d, DebugLogger)

    -- Clear previous log
    if enabled then
        love.filesystem.write(LOG_FILE, "=== MATCH DEBUG LOG ===\n")
        love.filesystem.append(LOG_FILE, "Started at: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
    end

    return d
end

function DebugLogger:getTimestamp()
    return string.format("%.3f", love.timer.getTime() - self.startTime)
end

function DebugLogger:log(message)
    if not enabled then return end

    local timestamp = self:getTimestamp()
    local logLine = "[" .. timestamp .. "s] " .. message .. "\n"
    love.filesystem.append(LOG_FILE, logLine)
end

function DebugLogger:logCardAction(card, phase)
    if not enabled then return end

    local msg = string.format(
        "CARD_ACTION: %s %s | cooldown=%.3fs timer=%.3fs progress=%.1f%% slowed=%s frozen=%s",
        phase,
        card.position,
        card.cooldown,
        card.timer,
        card:getProgress() * 100,
        tostring(card.isSlowed),
        tostring(card.isFrozen)
    )
    self:log(msg)
end

function DebugLogger:logCardUpdate(card, dt, acted)
    if not enabled then return end

    -- Only log every 60 frames to avoid spam, or if card acted
    self.frameCount = self.frameCount + 1
    if not acted and self.frameCount % 60 ~= 0 then
        return
    end

    local msg = string.format(
        "UPDATE: %s | dt=%.4f cooldown=%.3fs timer=%.3fs acted=%s",
        card.position,
        dt,
        card.cooldown,
        card.timer,
        tostring(acted)
    )
    self:log(msg)
end

function DebugLogger:logStatusEffect(targetCard, effect, duration)
    if not enabled then return end

    local msg = string.format(
        "STATUS_EFFECT: %s got %s for %.1fs (already had: slowed=%s frozen=%s)",
        targetCard.position,
        effect,
        duration,
        tostring(targetCard.isSlowed),
        tostring(targetCard.isFrozen)
    )
    self:log(msg)
end

function DebugLogger:logYardGeneration(card, baseYards, boostedYards, coachYards)
    if not enabled then return end

    local msg = string.format(
        "YARDS: %s generated %.2f yards (base=%.2f boosted=%.2f coach=%.2f)",
        card.position,
        coachYards,
        baseYards,
        boostedYards,
        coachYards
    )
    self:log(msg)
end

function DebugLogger:logPhaseChange(newPhase)
    if not enabled then return end

    self:log("=== PHASE CHANGE: " .. newPhase .. " ===")
end

function DebugLogger:logDownAdvance(down, downTimer)
    if not enabled then return end

    local msg = string.format(
        "DOWN_ADVANCE: Down %d started (timer=%.1fs)",
        down,
        downTimer
    )
    self:log(msg)
end

function DebugLogger:logCardCreation(card)
    if not enabled then return end

    local msg = string.format(
        "CARD_CREATED: %s %s | speed=%.2fs cooldown=%.2fs type=%s",
        card.position,
        card.cardType,
        card.speed,
        card.cooldown,
        card.cardType
    )
    self:log(msg)
end

function DebugLogger:logSpeedAnomaly(card, message)
    if not enabled then return end

    local msg = string.format(
        "!!! SPEED_ANOMALY: %s | %s | cooldown=%.3fs timer=%.3fs",
        card.position,
        message,
        card.cooldown,
        card.timer
    )
    self:log(msg)
end

function DebugLogger:disable()
    enabled = false
end

function DebugLogger:enable()
    enabled = true
end

return DebugLogger
