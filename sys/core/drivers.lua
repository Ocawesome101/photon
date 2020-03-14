-- Device drivers --

local loaded = drivers
local driverpath = "/sys/drivers/"
local component = component

_G.drivers = {}

local function path(d)
  return driverpath .. d .. ".lua"
end

function drivers.loadDriver(driver)
  checkArg(1, driver, "string")
  if loaded[driver] then
    return loaded[driver]
  end
  local ok, err = loadfile(path(driver))
  if not ok then
    return nil, err
  end
  ok = ok(component)
  loaded[driver] = ok
  return ok
end

function drivers.unloadDriver(driver)
  checkArg(1, driver, "string")
  if loaded[driver] then
    loaded[driver] = nil
  else
    return nil, "Driver not loaded"
  end
end
