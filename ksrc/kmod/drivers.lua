-- Load drivers
local driverpath = "/boot/drivers/"
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
      return false, err
    end
    return ok
  end
  return false, "Driver not found"
end
_G.drivers = {}
for _, driver in ipairs(_CONFIG.drivers) do
  logger.log("Loading driver " .. driver)
  local ok, err = load_driver(driver)
  if not ok and err then
    logger.log(string.format("Failed to load driver %s: %s", driver, err))
  else
    _G.drivers[driver] = ok
  end
end
