local monitor = peripheral.wrap("left")
print(monitor)
if (monitor == nil) then
    monitor = term
    print(monitor)

end
print(monitor)

local reactor = peripheral.wrap("back")
if (reactor == nil) then
    -- Not attached to back, test lan
    reactor = peripheral.wrap("BigReactors_Reactor_0")

    if (reactor == nil) then 
        print("No reactor detected. Please attach a reactor computer port to the 'back' of the computer or via modem(s). Program Shutting down.")
        sleep(1)
        exit()
    end
end

local Objects = {}
  
local function table_sort(tosort, order)
    if (order == -1) then
      table.sort(tosort, function(a, b) return a > b end)
    elseif (order == 1) then
      table.sort(tosort)
    end
end
  
local function str_round(x, d, p)
    local fstring_round = string.format("%."..d.."f", x)
    local _, _, minus, int, fraction = fstring_round:find('([-]?)(%d+)([.]?%d*)')
  
    -- reverse the int-string and append a comma to all blocks of 3 digits
    int = int:reverse():gsub("(%d%d%d)", "%1,")
  
    -- reverse the int-string back remove an optional comma and put the 
    -- optional minus and fractional part back
    return string.format("%"..p.."s", minus .. int:reverse():gsub("^,", "") .. fraction)
end
  
local function get_rods()
    local rods = {}
    for r = 1, reactor.getNumberOfControlRods() do
      table.insert(rods, reactor.getControlRodName(r - 1))
    end
  
    table.sort(rods)
  
    return rods
end
  
local function writeline(...)
    local x, y = monitor.getCursorPos()
    local args = { select(1, ...) }
    local toPrint = ""
    for i = 1, #args do
      toPrint = toPrint..args[i]
    end
  
    monitor.write(toPrint.."")
    monitor.setCursorPos(x, y + 1)
end
  
local function clear()
    monitor.clear()
    monitor.setCursorPos(1, 1)
end
  
local function _startup_(bufMin)
    clear()
    writeline("Starting Up NucleBrain.")
  
    if (reactor.getEnergyStored() < bufMin) then
      reactor.setAllControlRodLevels(0)
    else
      reactor.setAllControlRodLevels(100)
    end
    sleep(0.1)
    writeline("Control Rods Engaged At: "..reactor.getControlRodLevel(0).."% Insertion.")
  
    reactor.setActive(true)
    writeline("Reactor Online.")
  
    local cx, cy, b
    repeat
      b = reactor.getEnergyStored()
      cx, cy = monitor.getCursorPos()
      writeline("Charging: "..str_round(reactor.getEnergyStored(), 3, 11).." FE")
      monitor.setCursorPos(cx, cy)
      sleep(0.1)
    until (b >= bufMin)
  
    monitor.setCursorPos(cx, cy + 1)
    writeline("Startup Complete.")
  
    sleep(0.25)
    return b
end
  
local function shutdown()
    clear()
    writeline("Shutting Down NucleBrain.")
  
    reactor.setAllControlRodLevels(100)
    writeline("Control Rods Disengaged.")
  
    reactor.setActive(false)
    writeline("Reactor Disabled.\n Have a nice day.")
  
    sleep(0.5)
    clear()
end

local function ToggleReactor()
    if (reactor.getActive() == true) then reactor.setActive(false)
    else reactor.setActive(true) end
end
  
  local function avgControlRodLevel()
    local n = reactor.getNumberOfControlRods()
    local avg = 0
    for r = 0, n - 1 do
      avg = avg + reactor.getControlRodLevel(r)
    end
  
    return math.floor(avg / n)
  end
  
  local function status()
    if (reactor.getActive()) then
      return "On"
    end
  
    return "Off"
  end


-- -- -- -- -- -- -- --

-- -- -- -- -- -- -- --

  -- Libraries
Gui = {}

-- Helper Functions
local function filledString(chr, width)
    local str = ""

    for _ = 1, width do
        str = str..chr
    end

    return str
end

local function deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            setmetatable(copy, deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function drawText(text, where, pos, fgColor, bgColor)     
    -- Draw text
    local tempFG = where.getTextColor()
    local tempBG = where.getBackgroundColor()
    
    if (fgColor ~= nil) then
        if (type(fgColor) == "string") then where.setTextColor(colors.fromBlit(fgColor))
        else where.setTextColor(fgColor) end
    end

    if (bgColor ~= nil) then
        if (type(bgColor) == "string") then where.setBackgroundColor(colors.fromBlit(bgColor))
        else where.setBackgroundColor(bgColor) end
    end

    where.setCursorPos(pos[1], pos[2])
    writeline(text)

    where.setTextColor(tempFG)
    where.setBackgroundColor(tempBG)
end

-- Primitives --
-- Color
Gui.Color = {fg = "0", bg = "f", hor_fg = "0", hor_bg = "f"}
function Gui.Color:new(obj)
    obj = obj or {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Gui.Color:clone()
    return deepcopy(self)
end

-- Rect
Gui.Rect = {width = 1, height = 1, chr = " ", fillColor = Gui.Color:clone(), outlineColor = Gui.Color:clone(), x = 1, y = 1, title = "", titleFG = nil, titleBG = nil}
function Gui.Rect:new(obj)
    obj = obj or {}
    setmetatable(obj, self)
    self.__index = self
    
    obj.outlineColor = obj.outlineColor:clone()
    obj.fillColor = obj.fillColor:clone()

    obj.outlineHor = filledString(obj.chr, obj.width)
    obj.outlineColor.hor_fg = filledString(obj.outlineColor.fg, obj.width)
    obj.outlineColor.hor_bg = filledString(obj.outlineColor.bg, obj.width)

    obj.internal = filledString(obj.chr, obj.width - 2)
    obj.fillColor.fg = filledString(obj.fillColor.fg, obj.width - 2)
    obj.fillColor.bg = filledString(obj.fillColor.bg, obj.width - 2)

    obj.id = "rect"

    obj.titleXPos = obj.x + math.floor(obj.width / 2 - #obj.title / 2)

    return obj
end

function Gui.Rect:blit(screen)
    screen.setCursorPos(self.x, self.y)
    screen.blit(self.outlineHor, self.outlineColor.hor_fg, self.outlineColor.hor_bg)

    drawText(self.title, screen, {self.titleXPos, self.y}, self.titleFG, self.titleBG)

    for i = (self.y + 1), (self.height) do
        screen.setCursorPos(self.x, i)
        screen.blit(self.chr, self.outlineColor.fg, self.outlineColor.bg)
        screen.blit(self.internal, self.fillColor.fg, self.fillColor.bg)
        screen.blit(self.chr, self.outlineColor.fg, self.outlineColor.bg)
    end
    screen.setCursorPos(self.x, self.y + self.height - 1)
    screen.blit(self.outlineHor, self.outlineColor.hor_fg, self.outlineColor.hor_bg)
end

function Gui.Rect:setX(x)
    self.x = x
end

function Gui.Rect:setY(y)
    self.y = y
end

function Gui.Rect:setPos(x, y)
    self.x = x;
    self.y = y;
end

-- Dynamicly updated shapes --

-- Button
Gui.Button = Gui.Rect:new{colorOnPress=nil, onPress=nil, onPressArgs=nil}
function Gui.Button:new(obj)
    obj = obj or {}

    setmetatable(Gui.Rect:new(obj), {__index = self})

    if (obj.colorOnPress ~= nil) then
        obj.colorOnPress.fg = filledString(obj.colorOnPress.fg, obj.width - 2)
        obj.colorOnPress.bg = filledString(obj.colorOnPress.bg, obj.width - 2)
    end

    obj.id = "button"

    return obj
end

function Gui.Button:isPressed(x, y)
    self.fillColor.fg = filledString(self.fillColor.fg, self.width - 2)
    self.fillColor.bg = filledString(self.fillColor.bg, self.width - 2)

    if (x >= (self.x + 1) and x <= (self.x + self.width)) then
        if (y > (self.y) and y < (self.y + self.height - 1)) then
            if (self.onPressArgs == nil) then self.onPress() else self.onPress(self.onPressArgs) end
            
            if (self.colorOnPress ~= nil) then
                self.fillColor.fg = filledString(self.colorOnPress, self.width - 2)
                self.fillColor.bg = filledString(self.colorOnPress, self.width - 2)
            end
        end
    end
end

Gui.ToggleButton = Gui.Button:new{}
function Gui.ToggleButton:new(obj)
    obj = obj or {}

    setmetatable(Gui.Button:new(obj), {__index = self})

    obj.depressed = false

    return obj
end

function Gui.ToggleButton:isPressed(x, y)
    if (x >= (self.x + 1) and x <= (self.x + self.width)) then
        if (y > (self.y) and y < (self.y + self.height - 1)) then
            local temp = self.fillColor
            self.fillColor = self.colorOnPress
            self.colorOnPress = temp

            if (self.onPressArgs == nil) then self.onPress() else self.onPress(self.onPressArgs) end
        end
    end
end

-- Progress Bar
Gui.ProgressBar = Gui.Rect:new{min=0, max=100, barChr = " ", barColor=Gui.Color:clone(), orientation="v", inverted = false}

function Gui.ProgressBar:new(obj)
    obj = obj or {}

    setmetatable(Gui.Rect:new(obj), {__index = self})

    obj.barColor = obj.barColor:clone()
    
    obj.barHeight = obj.height - 2
    if (obj.inverted) then
        obj.barWidth = obj.width
    else
        obj.barWidth = obj.width - 2
    end

    obj.bar = filledString(obj.barChr, obj.barWidth)
    obj.barColor.fg = filledString(obj.barColor.fg, obj.barWidth)
    obj.barColor.bg = filledString(obj.barColor.bg, obj.barWidth)

    obj.dif = obj.max - obj.min
    obj.progress = 0
    obj.discreteProgress = obj.min

    return obj
end

function Gui.ProgressBar:setPercentProgress(progress)
    self.progress = progress
end

function Gui.ProgressBar:getPercentProgress()
    return self.progress
end

function Gui.ProgressBar:getDiscreteProgress()
    return self.barHeight * self.progress
end

function Gui.ProgressBar:blit(screen)
    local progress = math.ceil(self:getDiscreteProgress())

    screen.setCursorPos(self.x, self.y)
    screen.blit(self.outlineHor, self.outlineColor.hor_fg, self.outlineColor.hor_bg)

    drawText(self.title, screen, {self.titleXPos, self.y}, colors.black, self.outlineColor.hor_bg:sub(1,1))

    if (self.orientation == "v") then
        for i = (self.y + 1), (self.y + self.height - 2) do
            screen.setCursorPos(self.x, i)
            screen.blit(self.chr, self.outlineColor.fg, self.outlineColor.bg)

            if (i < self.y + (self.barHeight + 1 - progress)) then
                screen.blit(self.internal, self.fillColor.fg, self.fillColor.bg)
            elseif (i == self.y + (self.barHeight + 1 - progress)) then
                -- Set the background
                screen.blit(self.bar, self.barColor.fg, self.barColor.bg)
                
                -- Draw text
                drawText(str_round(100 * self.progress, 1, 3).."%", screen, {self.x+2, i}, nil, self.barColor.bg:sub(1, 1))

                -- reposition for the outline
                screen.setCursorPos(self.x+1+#self.barColor.bg, i)
            else
                screen.blit(self.bar, self.barColor.fg, self.barColor.bg)
            end

            screen.blit(self.chr, self.outlineColor.fg, self.outlineColor.bg)
        end
    end

    screen.setCursorPos(self.x, self.y + self.height - 1)
    screen.blit(self.outlineHor, self.outlineColor.hor_fg, self.outlineColor.hor_bg)
end

-- Slider
Gui.Slider = Gui.ProgressBar:new{inverted = false}

function Gui.Slider:new(obj)
    obj = obj or {}

    setmetatable(Gui.ProgressBar:new(obj), {__index = self})

    obj.id = "slider"

    return obj
end

function Gui.Slider:blit(screen)
    local progress = math.ceil(self:getDiscreteProgress())

    screen.setCursorPos(self.x, self.y)
    screen.blit(self.outlineHor, self.outlineColor.hor_fg, self.outlineColor.hor_bg)

    drawText(self.title, screen, {self.titleXPos, self.y}, colors.black, self.outlineColor.hor_bg:sub(1,1))

    if (self.orientation == "v") then
        for i = (self.y + 1), (self.y + self.height - 2) do
            screen.setCursorPos(self.x, i)
            screen.blit(self.chr, self.outlineColor.fg, self.outlineColor.bg)

            if (i == self.y + (self.barHeight + 1 - progress)) then
                -- Set the background
                screen.blit(self.bar, self.barColor.fg, self.barColor.bg)
                
                -- Draw text
                drawText(str_round(100 * self.progress, 1, 3).."%", screen, {self.x+2, i}, nil, self.barColor.bg:sub(1, 1))

                -- reposition for the outline
                screen.setCursorPos(self.x+1+#self.barColor.bg, i)
            else
                screen.blit(self.internal, self.fillColor.fg, self.fillColor.bg)
            end

            screen.blit(self.chr, self.outlineColor.fg, self.outlineColor.bg)
        end
    end

    screen.setCursorPos(self.x, self.y + self.height - 1)
    screen.blit(self.outlineHor, self.outlineColor.hor_fg, self.outlineColor.hor_bg)
end

function Gui.Slider:setAtLevel(x, level)
    if (x >= (self.x + 1) and x <= (self.x + self.barWidth)) then
        if (level > (self.y) and level < (self.y + self.height - 1)) then
            if (self.orientation == "v") then
                local y = level - self.y - 1 -- offset
        
                local max = self.barHeight - 1
                local min = 0
                local dif = self.dif
        
                self.progress = 1 - ((dif * (y - min)) / (max - min) + self.min) / dif
            elseif (self.orientation == "h") then
        
            end
        end
    end
end

-- Group
Gui.Group = {}
function Gui.Group:new(obj)
    obj = obj or {}
    setmetatable(obj, {__index = self})
    return obj
end

function Gui.Group:blit(screen)
    for _, asset in ipairs(self) do
        asset:blit(screen)
    end
end

-- Window (Background + an equal render level group)
Gui.Window = {backgroundRect = nil, overlayed = {}}
function Gui.Window:new(obj)
    obj = obj or {}
    setmetatable(obj, {__index = self})
    return obj
end

function Gui.Window:blit(screen)
    self.backgroundRect:blit(screen)
    for _, asset in pairs(self.overlayed) do
        asset:blit(screen)
    end
end

-- -- -- -- -- -- -- --

-- -- -- -- -- -- -- --

-- Gui Elements --
local FEBar = Gui.Color:new{fg="0", bg="e"}

local lblueBG = Gui.Color:new{fg="0", bg="3"}
local blueBar = Gui.Color:new{fg="0", bg="b"}
local fuelBar = Gui.Color:new{fg="0", bg="4"}

local black_bg = Gui.Color:new{bg="f"}
local grey_bg = Gui.Color:new{bg="8"}
local white_bg = Gui.Color:new{bg="0"}

local red_bg = Gui.Color:new{fg="0", bg="e"}
local green_bg = Gui.Color:new{fg="0", bg="d"}

local gui_ex = Gui.Color:new{bg="4"}

local defaultMonitorScale = monitor.getTextScale()
local programActive = false
local activeRod = 0
local FEDrain = 0
local maxFEDrain = 0
local maxFEGeneration = 0

local FECapacity = reactor.getEnergyCapacity()
local fuelCapacity = reactor.getFuelAmountMax()

local bufMax = FECapacity * 0.75
local bufMin = FECapacity * 0.25

local monitor_width, monitor_height = monitor.getSize()

local ratios = {
    targetMin = {w=0.125, h=0.45},
    targetMax = {w=0.125, h=0.45},
    FEStored = {w=0.125, h=0.9},
    fuelRatio = {w=0.125, h=0.9},
    reactivity = {w=0.125, h=0.9},
    FEGen = {w=0.125, h=0.9},
    stats = {w=3.75, h=0.9},
    button = {w=0.1, h=0.1}
}

local dimensions = {
    targetMin = {w=math.floor(math.floor(ratios.targetMin.w * monitor_width)), h=math.floor(ratios.targetMin.h * (monitor_height-2))},
    targetMax = {w=math.floor(ratios.targetMax.w * monitor_width), h=math.floor(ratios.targetMax.h * (monitor_height-2))},
    FEStored = {w=math.floor(ratios.FEStored.w * monitor_width), h=math.floor(ratios.FEStored.h * (monitor_height-2))},
    FEGen = {w=math.floor(ratios.FEGen.w * monitor_width), h=math.floor(ratios.FEGen.h * (monitor_height-2))},
    fuelRatio = {w=math.floor(ratios.fuelRatio.w * monitor_width), h=math.floor(ratios.fuelRatio.h * (monitor_height-2))},
    reactivity = {w=math.floor(ratios.reactivity.w * monitor_width), h=math.floor(ratios.reactivity.h * (monitor_height-2))},
    stats = {w=math.floor(ratios.stats.w * monitor_width), h=math.floor(ratios.stats.h * (monitor_height-2))},
    button = {w=math.floor(ratios.button.w * monitor_width), h=math.ceil(ratios.button.h * (monitor_height-2))}
}

local FEGenMeter = Gui.ProgressBar:new{fillColor=grey_bg, title="FE Gen", width=dimensions.FEGen.w, height=dimensions.FEGen.h, max = dimensions.FEGen.h-2, outlineColor=white_bg, barColor=FEBar, x=2, y=dimensions.button.h+2}
local FEStoredMeter = Gui.ProgressBar:new{fillColor=grey_bg, title="Battery", width=dimensions.FEStored.w, height=dimensions.FEStored.h, max = dimensions.FEStored.h-2, outlineColor=white_bg, barColor=FEBar, x=FEGenMeter.x+dimensions.FEGen.w, y=dimensions.button.h+2}
local fuelRatioMeter = Gui.ProgressBar:new{fillColor=grey_bg, title="Fuel", width=dimensions.fuelRatio.w, height=dimensions.fuelRatio.h, max = dimensions.fuelRatio.h-2, outlineColor=white_bg, barColor=fuelBar, x=FEStoredMeter.x+dimensions.FEStored.w, y=dimensions.button.h+2}
local reactivityMeter = Gui.ProgressBar:new{fillColor=grey_bg, title="React.", width=dimensions.reactivity.w, height=dimensions.reactivity.h, max = dimensions.reactivity.h-2, outlineColor=white_bg, barColor=blueBar, x=fuelRatioMeter.x+dimensions.fuelRatio.w, y=dimensions.button.h+2}

local FETargetMax = Gui.Slider:new{fillColor=grey_bg, title="RFTMax", width=dimensions.targetMax.w, height=dimensions.targetMax.h, max = dimensions.targetMax.h-2, outlineColor=white_bg, barColor=blueBar, x=reactivityMeter.x+dimensions.reactivity.w, y=dimensions.button.h+2}
local FETargetMin = Gui.Slider:new{fillColor=grey_bg, title="RFTMin", width=dimensions.targetMin.w, height=dimensions.targetMin.h, max = dimensions.targetMin.h-2, outlineColor=white_bg, barColor=blueBar, x=reactivityMeter.x+dimensions.reactivity.w, y=dimensions.button.h+2+dimensions.targetMax.h}

local ToggleReactorButton = Gui.ToggleButton:new{colorOnPress=red_bg, onPress=ToggleReactor, fillColor=green_bg, width=dimensions.button.w, height=dimensions.button.h, outlineColor=white_bg, x=2, y=2}

FETargetMax:setPercentProgress(bufMax / FECapacity)
FETargetMin:setPercentProgress(bufMin / FECapacity)

Objects.FEMaxT = FETargetMax
Objects.FEMinT = FETargetMin
Objects.OnOffButton = ToggleReactorButton

local backgroundWindow = Gui.Rect:new{title="NucleBrain V2.0.0", titleFG=colors.black, titleBG=colors.lightGray, width = monitor_width, height = monitor_height, fillColor=gui_ex, outlineColor=grey_bg}
local window = Gui.Window:new{backgroundRect=backgroundWindow, overlayed={FEGen=FEGenMeter, FEStored=FEStoredMeter, FuelRatio=fuelRatioMeter, Reactivity=reactivityMeter, FEMaxT=FETargetMax, FEMinT=FETargetMin, OnOffButton=ToggleReactorButton}}

local function gui()
    while true do

        sleep(0.05)

        if (programActive) then
            clear()
            window:blit(monitor)
        
        --   writeline("Reactor Status: "..status())
        --   writeline("Reactor Buffer: "..str_round(reactor.getEnergyStored(), 3, 11).." FE")
        --   writeline("Average FE Output: "..str_round(StatsFEGen, 3, 9).." FE/t")
        --   writeline("Average Insertion: "..avgControlRodLevel().."%")
        --   writeline("Fuel Cons.: "..str_round(reactor.getFuelConsumedLastTick(), 3, 8).." mB/t")
        --   writeline("Quit: 'x', Toggle Power: 't'")
        --   writeline("Fully Insert All Rods: 'f'")
        --   writeline("Fully Retract All Rods: 'r'")
        --   writeline("")
        --   writeline("Max Observed Power Generation: "..str_round(maxFEGeneration, 3, 11).." FE/t")
        --   writeline("Max Observed Power Draw: "..str_round(maxFEDrain, 3, 11).." FE/t")
        else
            local rBuff = str_round(reactor.getEnergyStored(), 3, 11)
        end
    end
end

local function startup(bufMin)
    clear()
    monitor.setTextScale(0.5)

    local mw, mh = monitor.getSize()

    local _backgroundWindow = Gui.Rect:new{width = mw, height = mh, fillColor=Gui.Color:new{bg="4"}, outlineColor=Gui.Color:new{bg="8"}}

    local mini_window = Gui.Rect:new{width=16, height=4, outlineColor=Gui.Color:new{bg="0"}, x=mw/2-7, y=mh/2-1}
    local _window = Gui.Window:new{backgroundRect=_backgroundWindow, overlayed={a=mini_window}}

    _window:blit(monitor)
        
    monitor.setBackgroundColor(8)

    monitor.setCursorPos(mw/2-7, mh/2)
    monitor.write("   NucleBrain   ")
    
    monitor.setCursorPos(mw/2-7, mh/2+1)
    monitor.write(" Starting Up... ")
    
    monitor.setBackgroundColor(16)

    sleep(1)
    _startup_(bufMin)
end
  
local function handleEvents()
    repeat
        local events = {os.pullEvent()}
        local event = events[1]
        
        if (event == "monitor_touch") then
            local x, y = events[3], events[4]

            for _, obj in pairs(Objects) do
                if (obj.id == "slider") then
                    obj:setAtLevel(x, y)
                elseif (obj.id == "button") then
                    obj:isPressed(x, y)

                    sleep(0.15)
                end
            end

        elseif (event == "key") then
            local key = events[2]

            if key == keys.t then
                reactor.setActive(not reactor.getActive())
            elseif key == keys.r then
                reactor.setAllControlRodLevels(0)
            elseif key == keys.f then
                reactor.setAllControlRodLevels(100)
            end

            sleep(0.15)
        end
  
    until (event == "key" and events[2] == keys.x)
  end
  
  --Main Code--
  
  local function init(bufMin)
    startup(bufMin)
  
    local rods = get_rods()
    table_sort(rods, 1)
    return rods
  end

local function sensors()
    local FEGen = 0
    local StatsFEGen = 0
    local FEGenOverTime = 0

    local FEObservations = 0
    local maxFEObservations = 25

    while true do
        FEGen = reactor.getEnergyProducedLastTick()
        if (FEGen > maxFEGeneration) then maxFEGeneration = FEGen end

        FEDrain = reactor.getEnergyStored()

        sleep(0.05)

        FEDrain = FEDrain - reactor.getEnergyStored()
        if (FEDrain > maxFEDrain) then maxFEDrain = FEDrain end

        -- Observe power over time for a better picture of stats
        FEGenOverTime = FEGenOverTime + reactor.getEnergyProducedLastTick()
        FEObservations = FEObservations + 1

        if (FEObservations == maxFEObservations) then
            StatsFEGen = FEGenOverTime / maxFEObservations
            
            FEObservations = 0
            FEGenOverTime = StatsFEGen -- Setting this smooths the data
        end

        window.overlayed.FEStored.progress = reactor.getEnergyStored() / FECapacity
        window.overlayed.FuelRatio.progress = reactor.getFuelAmount() / fuelCapacity
        window.overlayed.Reactivity.progress = reactor.getFuelReactivity()
        window.overlayed.FEGen.progress = StatsFEGen / maxFEGeneration
    end
end
  
local function main()
    local bMin = bufMin
    local bMax = bufMax

    local minRodLevel = 0;
    local maxRodLevel = 100
  
    local buffer = reactor.getEnergyStored()
    local bufDisableOffStandby = bMax * 0.9
  
    local bufferRange = 0
    local insertionFactor = 0
  
    local rods = init(bufMin)
  
    local standby = false
  
    programActive = true
    while true do
        buffer = reactor.getEnergyStored()

        bMin = FECapacity * FETargetMin:getPercentProgress()
        bMax = FECapacity *FETargetMax:getPercentProgress()
        bufDisableOffStandby = bMax * 0.9
  
        bufferRange = bMin + (bMax - bMin)
        insertionFactor = bufferRange / 100

        -- Necessary to avoid a game deadlock
        -- If this is not here the entire game will stop functioning properly
        sleep(0.05)

        if (standby == true and buffer < bufDisableOffStandby) then standby = false end
        
        if (standby == false) then
            if (buffer >= bMax) then
                -- Max insertion
                reactor.setAllControlRodLevels(maxRodLevel)
                standby = true

            elseif (buffer <= bMin) then
                -- Min insertion
                reactor.setAllControlRodLevels(minRodLevel)

            else
                local bufferDelta = bufferRange - reactor.getEnergyStored()
                local level = maxRodLevel - math.ceil(bufferDelta / insertionFactor)

                reactor.setControlRodLevel(activeRod, level)
                activeRod = activeRod + 1

                if (activeRod >= #rods) then activeRod = 0 end
            end
        end
    end
end

parallel.waitForAny(main, handleEvents, gui, sensors)
shutdown()