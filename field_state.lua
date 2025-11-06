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
        downYards = 0,               -- Yards gained this set of downs (can go negative if losing ground)
        yardsNeeded = yardsNeeded or 80,  -- Yards needed to score TD (80 default, 68 for Special Teams)
        firstDownLine = 10,          -- Field position where first down is achieved (starts 10 yards ahead)

        -- Down tracking
        currentDown = 1,             -- Current down (1-4)
        downTimer = 2.0,             -- Time remaining in current down (2 seconds)
        downDuration = 2.0,          -- Duration of each down

        -- Field position (for turnovers and visualization)
        fieldPosition = 20,          -- Current yard line (0-100)
        drivingForward = true,       -- True = driving toward 100, False = driving toward 0

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

    -- Update field position based on direction
    if self.drivingForward then
        -- Driving toward 100 (player offense)
        self.fieldPosition = self.fieldPosition + yards
    else
        -- Driving toward 0 (AI offense)
        self.fieldPosition = self.fieldPosition - yards
    end

    -- Check for touchdown
    if self.totalYards >= self.yardsNeeded then
        self.touchdownScored = true
    end

    -- Check for first down (reached or passed the first down line)
    if self.fieldPosition >= self.firstDownLine and self.drivingForward then
        self:achieveFirstDown()
    elseif self.fieldPosition <= self.firstDownLine and not self.drivingForward then
        self:achieveFirstDown()
    end
end

function FieldState:removeYards(yards)
    -- Remove yards from totalYards (clamped to 0) and downYards (can go negative)
    self.totalYards = math.max(0, self.totalYards - yards)
    self.downYards = self.downYards - yards  -- Allow negative to track loss of ground

    -- Update field position based on direction (reverse of addYards)
    if self.drivingForward then
        -- Driving toward 100, removing yards moves back
        self.fieldPosition = math.max(0, math.min(100, self.fieldPosition - yards))
    else
        -- Driving toward 0, removing yards moves back
        self.fieldPosition = math.max(0, math.min(100, self.fieldPosition + yards))
    end
end

function FieldState:achieveFirstDown()
    -- Reset down and down yards
    self.currentDown = 1
    self.downYards = 0
    self.downTimer = self.downDuration

    -- Set new first down line (10 yards ahead of current position)
    if self.drivingForward then
        self.firstDownLine = self.fieldPosition + 10
    else
        self.firstDownLine = self.fieldPosition - 10
    end
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
        -- Check if we've reached the first down line
        local reachedFirstDown = false
        if self.drivingForward then
            reachedFirstDown = self.fieldPosition >= self.firstDownLine
        else
            reachedFirstDown = self.fieldPosition <= self.firstDownLine
        end

        if not reachedFirstDown then
            self.turnoverOccurred = true
            if FieldState.logger then
                FieldState.logger:log("TURNOVER: Failed to reach first down line in 4 downs")
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

function FieldState:reset(startingPosition, yardsNeeded, drivingForward)
    -- Reset for new drive
    self.totalYards = 0
    self.downYards = 0
    self.currentDown = 1
    self.downTimer = self.downDuration
    self.touchdownScored = false
    self.turnoverOccurred = false

    -- Set driving direction (default to forward if not specified)
    if drivingForward ~= nil then
        self.drivingForward = drivingForward
    else
        self.drivingForward = true  -- Default to player direction
    end

    -- Set field position and yards needed
    if startingPosition and yardsNeeded then
        -- Both provided: use them directly (for turnovers)
        self.fieldPosition = startingPosition
        self.yardsNeeded = yardsNeeded
    elseif yardsNeeded then
        -- Only yards needed: calculate starting position based on direction
        self.yardsNeeded = yardsNeeded
        if self.drivingForward then
            -- Driving toward 100, start at 100 - yardsNeeded
            self.fieldPosition = 100 - yardsNeeded
        else
            -- Driving toward 0, start at 0 + yardsNeeded
            self.fieldPosition = yardsNeeded
        end
    else
        -- Default: start at own 20, need 80 yards, driving forward
        self.fieldPosition = 20
        self.yardsNeeded = 80
        self.drivingForward = true
    end

    -- Set first down line (10 yards ahead of starting position)
    if self.drivingForward then
        self.firstDownLine = self.fieldPosition + 10
    else
        self.firstDownLine = self.fieldPosition - 10
    end
end

function FieldState:getYardsToFirstDown()
    -- Calculate distance to first down line based on direction
    if self.drivingForward then
        return math.max(0, self.firstDownLine - self.fieldPosition)
    else
        return math.max(0, self.fieldPosition - self.firstDownLine)
    end
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
