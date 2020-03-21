-- Load drivers
local driverpath = "/sys/drivers/"
local function load_driver(driver)
  if bootfs.exists(driverpath .. driver .. ".lua") then
    local handle, err = bootfs.open(driverpath .. driver .. ".lua")
    local data = ""
    repeat
      local chunk = bootfs.read(handle, math.huge)
      data = data .. (chunk or "")
    until not chunk
    bootfs.close(handle)
    local ok, err = load(data, "=driver_" .. driver, "t", _G)
    if not ok then
      return nil, err
    end
    return pcall(ok)
  end
  return false, "Driver not found"
end
_G.drivers = {}
for _, driver in ipairs(_CONFIG.drivers) do
  logger.log("Loading driver " .. driver)
  local ok, ret = load_driver(driver)
  if not ok and ret then
    logger.log(string.format("Failed to load driver %s: %s", driver, ret))
  else
    _G.drivers[driver] = ret
  end
end
