local function wrap(name)
  -- Remember this order in case multiple peripherals are wrapped through "sides"

  local periph = peripheral.wrap(name)
  if (periph == nil) then periph = peripheral.wrap("up") end
  if (periph == nil) then periph = peripheral.wrap("down") end
  if (periph == nil) then periph = peripheral.wrap("left") end
  if (periph == nil) then periph = peripheral.wrap("right") end
  if (periph == nil) then periph = peripheral.wrap("front") end
  if (periph == nil) then periph = peripheral.wrap("back") end

  return periph
end

local monitor = wrap("left")
local reactor = wrap("back")

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

local function startup(bufMin)
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

local programActive = false
local activeRod = 0
local FEDrain = 0
local maxFEDrain = 0
local maxFEGeneration = 0

local function gui()
  local buffer = 0

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

    if (programActive) then
      clear()
      writeline("-----NucleBrain V1.0.0-----")
      writeline("Reactor Status: "..status())
      writeline("Reactor Buffer: "..str_round(reactor.getEnergyStored(), 3, 11).." FE")
      writeline("Average FE Output: "..str_round(StatsFEGen, 3, 9).." FE/t")
      writeline("Average Insertion: "..avgControlRodLevel().."%")
      writeline("Fuel Cons.: "..str_round(reactor.getFuelConsumedLastTick(), 3, 8).." mB/t")
      writeline("Quit: 'x', Toggle Power: 't'")
      writeline("Fully Insert All Rods: 'f'")
      writeline("Fully Retract All Rods: 'r'")
      writeline("")
      writeline("Max Observed Power Generation: "..str_round(maxFEGeneration, 3, 11).." FE/t")
      writeline("Max Observed Power Draw: "..str_round(maxFEDrain, 3, 11).." FE/t")
    else
      local rBuff = str_round(reactor.getEnergyStored(), 3, 11)
    end
  end
end

local function handleEvents()
  repeat
    local _, key = os.pullEvent()

    if key == keys.t then
      reactor.setActive(not reactor.getActive())
      sleep(0.15)
    elseif key == keys.r then
      reactor.setAllControlRodLevels(0)
      sleep(0.15)
    elseif key == keys.f then
      reactor.setAllControlRodLevels(100)
      sleep(0.15)
    end

  until key == keys.x
end

--Main Code--

local function init(bufMin)
  startup(bufMin)

  local rods = get_rods()
  table_sort(rods, 1)
  return rods
end

local function main()
  programActive = true

  local minRodLevel = 0;
  local maxRodLevel = 100

  local buffer = reactor.getEnergyStored()
  local bufMax = reactor.getEnergyCapacity() * 0.75
  local bufMin = reactor.getEnergyCapacity() * 0.25

  -- local bufDisableOnStandby = reactor.getEnergyCapacity() * 0.60
  local bufDisableOffStandby = reactor.getEnergyCapacity() * 0.40

  local bufferRange = bufMax - bufMin
  local insertionFactor = bufferRange / 100

  local rods = init(bufMin)

  local standby = false

  local hotGroup = 1

  while true do
    buffer = reactor.getEnergyStored()

    -- Necessary to avoid a game deadlock
      -- If this is not here the entire game will stop functioning properly
    sleep(0.05)

    if (standby == true and buffer < bufDisableOffStandby) then standby = false end
    
    if (standby == false) then
      if (buffer >= bufMax) then
        -- Max insertion
        reactor.setAllControlRodLevels(maxRodLevel)
        standby = true

      elseif (buffer <= bufMin) then
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

parallel.waitForAny(main, handleEvents, gui)
shutdown()
