-- field_state.lua
local lume = require("lib.lume")

local FieldState = {}
FieldState.__index = FieldState

-- Debug logger (set by match.lua)
FieldState.logger = nil

function FieldState:new(yardsNeeded)
    local f = {
        -- Yard tracking
        totalYards = 0,              -- Total yards gained this drive (0 to yardsNeeded)
        downYards = 0,               -- Yards gained this set of downs (0 to 10)
        yardsNeeded = yardsNeeded or 80,  -- Yards needed to score TD (80 default, 68 for Special Teams)

        -- Down tracking
        currentDown = 1,             -- Current down (1-4)
        downTimer = 2.0,             -- Time remaining in current down (2 seconds)
        downDuration = 2.0,          -- Duration of each down

        -- Field position (for turnovers)
        fieldPosition = 20,          -- Current yard line (20 = own 20)

        -- Flags
        touchdownScored = false,
        turnoverOccurred = false
    }
    setmetatable(f, FieldState)
    return f
end

function FieldState:update(dt)
    -- Update down timer
    self.downTimer = self.downTimer - dt

    if self.downTimer <= 0 then
        -- Down expired, advance to next down
        self:advanceDown()
    end
end

function FieldState:addYards(yards)
    -- Add yards to both counters
    self.totalYards = self.totalYards + yards
    self.downYards = self.downYards + yards
    self.fieldPosition = self.fieldPosition + yards

    -- Check for touchdown
    if self.totalYards >= self.yardsNeeded then
        self.touchdownScored = true
    end

    -- Check for first down
    if self.downYards >= 10 then
        self:achieveFirstDown()
    end
end

function FieldState:removeYards(yards)
    -- Remove yards from both counters (using lume.clamp for cleaner code)
    self.totalYards = lume.clamp(self.totalYards - yards, 0, math.huge)
    self.downYards = lume.clamp(self.downYards - yards, 0, math.huge)
    self.fieldPosition = lume.clamp(self.fieldPosition - yards, 20, 100)  -- Can't go back past own 20
end

function FieldState:achieveFirstDown()
    -- Reset down and down yards
    self.currentDown = 1
    self.downYards = 0
    self.downTimer = self.downDuration
end

function FieldState:advanceDown()
    self.currentDown = self.currentDown + 1
    self.downTimer = self.downDuration

    -- Log down advance
    if FieldState.logger then
        FieldState.logger:logDownAdvance(self.currentDown, self.downTimer)
    end

    -- Check for turnover on downs
    if self.currentDown > 4 then
        -- Check if we got the first down
        if self.downYards < 10 then
            self.turnoverOccurred = true
            if FieldState.logger then
                FieldState.logger:log("TURNOVER: Failed to get 10 yards in 4 downs")
            end
        else
            -- Got first down on 4th down
            self:achieveFirstDown()
        end
    end
end

function FieldState:hasTouchdown()
    return self.touchdownScored
end

function FieldState:isTurnover()
    return self.turnoverOccurred
end

function FieldState:getFieldPosition()
    return self.fieldPosition
end

function FieldState:reset(startingPosition, yardsNeeded)
    -- Reset for new drive
    self.totalYards = 0
    self.downYards = 0
    self.currentDown = 1
    self.downTimer = self.downDuration
    self.touchdownScored = false
    self.turnoverOccurred = false

    -- Set field position and yards needed
    if startingPosition and yardsNeeded then
        -- Both provided: use them directly (for turnovers)
        self.fieldPosition = startingPosition
        self.yardsNeeded = yardsNeeded
    elseif yardsNeeded then
        -- Only yards needed: calculate starting position
        self.yardsNeeded = yardsNeeded
        self.fieldPosition = 100 - yardsNeeded
    else
        -- Default: start at own 20, need 80 yards
        self.fieldPosition = 20
        self.yardsNeeded = 80
    end
end

function FieldState:getYardsToFirstDown()
    return math.max(0, 10 - self.downYards)
end

function FieldState:getYardsToTouchdown()
    return math.max(0, self.yardsNeeded - self.totalYards)
end

function FieldState:draw()
    love.graphics.print("Total Yards: " .. math.floor(self.totalYards) .. "/" .. self.yardsNeeded, 200, 20)
    love.graphics.print("Down: " .. self.currentDown .. " | Yards to 1st: " .. math.floor(self:getYardsToFirstDown()), 200, 40)
    love.graphics.print("Down Timer: " .. string.format("%.1f", self.downTimer), 200, 60)
end

return FieldState
