-- redstone card driver --

local component = ...

local redstone = component.list("redstone")()

if not redstone then
  return nil
end

local rs = {}

setmetatable(rs, {__index = function(_, k) error("Attempt to index redstone." .. k .. " (a nil value)") end})

function rs.input(side)
  checkArg(1, side, "number", "nil")
  return raw.getInput(side)
end

function rs.output(side, value)
  checkArg(1, side, "number", "table", "nil")
  checkArg(2, value, "number", "nil")
  if side and value then
    return raw.setOutput(side, value)
  elseif type(side) == "table" then
    return raw.setOutput(side)
  else
    return raw.getOutput(side)
  end
end

function rs.bundledInput(side, color)
  checkArg(1, side, "number", "nil")
  checkArg(2, color, "number", "nil")
  return raw.getBundledInput(side, color)
end

function rs.bundledOutput(side, color, value)
  checkArg(1, side, "number", "nil")
  checkArg(2, color, "number", "nil")
  checkArg(3, value, "number", "nil")
  if side and color and value then
    return raw.setBundledOutput(side, color, value)
  elseif type(side) == "table" then
    return raw.setBundledOutput(side)
  else
    return raw.getBundledOutput(side, color)
  end
end

function rs.comparatorInput(side)
  checkArg(1, side, "number")
  return raw.getComparatorInput(side)
end

function rs.wireless(value)
  checkArg(1, value, "boolean", "nil")
  if value == nil then
    return raw.getWirelessInput()
  else
    return raw.setWirelessOutput(value)
  end
end

function rs.frequency(freq)
  checkArg(1, freq, "number", "nil")
  if freq then
    return raw.setWirelessFrequency(freq)
  else
    return raw.getWirelessFrequency()
  end
end

function rs.threshold(thres)
  checkArg(1, thres, "number", "nil")
  if thres then
    return raw.setWakeThreshold(thres)
  else
    return raw.getWakeThreshold()
  end
end

return rs
