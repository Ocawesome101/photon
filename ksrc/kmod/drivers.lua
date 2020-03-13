-- Load drivers
local driverpath = "/boot/drivers/"
local function load_driver(driver)
  if bootfs.exists(driverpath .. driver) then
    local handle, err = bootfs.open(driverpath .. driver)
    local data = ""
    repeat
      local chunk = bootfs.read(handle, math.huge)
      data = data .. (chunk or "")
    until not chunk
    bootfs.close(handle)
  end
end
for _, driver in ipairs(_CONFIG.drivers) do
  logger.log("Attempting to load driver " .. driver)
  local ok, err = load_driver(driver)
  if not ok then
    logger.log(string.format("Failed to load driver %s: %s", driver, err))
  end
end
