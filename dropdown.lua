--- dropdown.lua
--- Dropdown UI Component
---
--- A reusable dropdown menu component for LÖVE2D.
--- Supports mouse interaction, keyboard navigation, and scaling.
---
--- Dependencies: ui_scale.lua (for scaling support)
--- Used by: options_menu.lua

local Dropdown = {}
Dropdown.__index = Dropdown

--- Creates a new dropdown instance
--- @param x number X position
--- @param y number Y position
--- @param width number Dropdown width
--- @param options table Array of option tables {value=..., label=...}
--- @param selectedValue any Initially selected value
--- @return table Dropdown instance
function Dropdown.new(x, y, width, options, selectedValue)
    local self = setmetatable({}, Dropdown)

    self.x = x
    self.y = y
    self.width = width
    self.height = 40
    self.options = options or {}
    self.selectedIndex = 1
    self.isOpen = false
    self.hoveredIndex = 0
    self.font = love.graphics.newFont(20)
    self.itemHeight = 35

    -- Find initial selected index
    if selectedValue then
        for i, opt in ipairs(self.options) do
            if opt.value == selectedValue then
                self.selectedIndex = i
                break
            end
        end
    end

    return self
end

--- Sets the options list
--- @param options table Array of option tables
--- @param selectedValue any Value to select
function Dropdown:setOptions(options, selectedValue)
    self.options = options

    -- Find selected index
    self.selectedIndex = 1
    if selectedValue then
        for i, opt in ipairs(self.options) do
            if opt.value == selectedValue then
                self.selectedIndex = i
                break
            end
        end
    end
end

--- Gets the currently selected option
--- @return table Selected option {value, label}
function Dropdown:getSelected()
    return self.options[self.selectedIndex]
end

--- Draws the dropdown
function Dropdown:draw()
    love.graphics.setFont(self.font)

    -- Draw main dropdown box
    if self.isOpen then
        love.graphics.setColor(0.3, 0.5, 0.7, 0.8)
    else
        love.graphics.setColor(0.2, 0.3, 0.4, 0.8)
    end
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)

    -- Draw border
    love.graphics.setColor(0.5, 0.6, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 5, 5)

    -- Draw selected option text
    love.graphics.setColor(1, 1, 1)
    local selectedLabel = self.options[self.selectedIndex] and self.options[self.selectedIndex].label or "None"
    love.graphics.printf(selectedLabel, self.x + 10, self.y + 10, self.width - 40, "left")

    -- Draw dropdown arrow
    local arrowX = self.x + self.width - 25
    local arrowY = self.y + self.height / 2
    self:drawArrow(arrowX, arrowY, self.isOpen)

    -- Draw dropdown list if open
    if self.isOpen then
        local listY = self.y + self.height + 2
        local maxVisibleItems = 6
        local visibleItems = math.min(#self.options, maxVisibleItems)
        local listHeight = visibleItems * self.itemHeight

        -- Draw list background
        love.graphics.setColor(0.15, 0.2, 0.25, 0.95)
        love.graphics.rectangle("fill", self.x, listY, self.width, listHeight, 5, 5)

        -- Draw list border
        love.graphics.setColor(0.5, 0.6, 0.7)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", self.x, listY, self.width, listHeight, 5, 5)

        -- Draw options
        for i, option in ipairs(self.options) do
            local itemY = listY + (i - 1) * self.itemHeight

            -- Skip if out of visible bounds
            if i > maxVisibleItems then
                break
            end

            -- Highlight hovered or selected item
            if i == self.hoveredIndex then
                love.graphics.setColor(0.4, 0.6, 0.8, 0.6)
                love.graphics.rectangle("fill", self.x + 2, itemY + 2, self.width - 4, self.itemHeight - 2)
            elseif i == self.selectedIndex then
                love.graphics.setColor(0.3, 0.5, 0.7, 0.4)
                love.graphics.rectangle("fill", self.x + 2, itemY + 2, self.width - 4, self.itemHeight - 2)
            end

            -- Draw option text
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(option.label, self.x + 10, itemY + 8, self.width - 20, "left")
        end
    end
end

--- Draws dropdown arrow indicator
--- @param x number Arrow X position
--- @param y number Arrow Y position
--- @param isOpen boolean Whether dropdown is open
function Dropdown:drawArrow(x, y, isOpen)
    love.graphics.setColor(1, 1, 1)

    if isOpen then
        -- Up arrow
        love.graphics.polygon("fill",
            x, y + 3,
            x + 6, y - 3,
            x + 12, y + 3
        )
    else
        -- Down arrow
        love.graphics.polygon("fill",
            x, y - 3,
            x + 6, y + 3,
            x + 12, y - 3
        )
    end
end

--- Handles mouse press events
--- @param mx number Mouse X position
--- @param my number Mouse Y position
--- @return boolean True if dropdown handled the click
function Dropdown:mousepressed(mx, my)
    -- Check if clicking on main dropdown box
    if mx >= self.x and mx <= self.x + self.width and
       my >= self.y and my <= self.y + self.height then
        self.isOpen = not self.isOpen
        return true
    end

    -- Check if clicking on dropdown list
    if self.isOpen then
        local listY = self.y + self.height + 2
        local maxVisibleItems = math.min(#self.options, 6)
        local listHeight = maxVisibleItems * self.itemHeight

        if mx >= self.x and mx <= self.x + self.width and
           my >= listY and my <= listY + listHeight then
            -- Calculate which item was clicked
            local itemIndex = math.floor((my - listY) / self.itemHeight) + 1

            if itemIndex >= 1 and itemIndex <= #self.options then
                self.selectedIndex = itemIndex
                self.isOpen = false
                return true
            end
        else
            -- Clicked outside dropdown, close it
            self.isOpen = false
            return true
        end
    end

    return false
end

--- Handles mouse movement for hover effects
--- @param mx number Mouse X position
--- @param my number Mouse Y position
function Dropdown:mousemoved(mx, my)
    self.hoveredIndex = 0

    if self.isOpen then
        local listY = self.y + self.height + 2
        local maxVisibleItems = math.min(#self.options, 6)
        local listHeight = maxVisibleItems * self.itemHeight

        if mx >= self.x and mx <= self.x + self.width and
           my >= listY and my <= listY + listHeight then
            local itemIndex = math.floor((my - listY) / self.itemHeight) + 1

            if itemIndex >= 1 and itemIndex <= #self.options then
                self.hoveredIndex = itemIndex
            end
        end
    end
end

--- Closes the dropdown
function Dropdown:close()
    self.isOpen = false
end

--- Checks if dropdown is open
--- @return boolean True if open
function Dropdown:isDropdownOpen()
    return self.isOpen
end

return Dropdown
