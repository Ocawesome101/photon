-- O-Kernel, the heart of OC-OS --

local _BUILD_ID = "177755e"

-- Boot filesystem proxy, for loading drivers. --
local addr = computer.getBootAddress()
local bootfs = component.proxy(addr)


-- Logging --
local logger = {}
do
  local invoke = component.invoke
  logger.log = function()end
  logger.prefix = "O-Kernel:"
  local gpu = component.list("gpu")()
  local screen = component.list("screen")()
  if gpu and screen then
    invoke(gpu, "bind", screen)
    local y = 1
    local w, h = invoke(gpu, "maxResolution")
    invoke(gpu, "setResolution", w, h)
    logger.log = function(...)
      local msg = table.concat({logger.prefix, ...}, " ")
      invoke(gpu, "set", 1, y, msg)
      if y < h then
        y = y + 1
      else
        invoke(gpu, "copy", 1, 1, w, h, 0, -1)
        invoke(gpu, "fill", 1, h, w, 1, " ")
      end
    end
  end
end
local function freeze(...)
  logger.log("ERR:", ...)
  while true do
    computer.pullSignal()
  end
end


-- Load kernel configuration from /kernel.cfg --
local _DEFAULT_CONFIG = {drivers = {"filesystem","logger","user_io","internet"},userspace = {sandbox = true},init="/sys/core/init.lua"}
local _CONFIG = {}
local handle = bootfs.open("/boot/kernel.cfg")
if not handle then
  _CONFIG = _DEFAULT_CONFIG
else
  local data = ""
  repeat
    local chunk = bootfs.read(handle, math.huge)
    data = data .. (chunk or "")
  until not chunk
  bootfs.close(handle)
  local ok, err = load("return " ..data, "=/boot/kernel.cfg", "t", {})
  if not ok then
    _CONFIG = _DEFAULT_CONFIG
  else
    local s, r = pcall(ok)
    if not s then
      _CONFIG = _DEFAULT_CONFIG
    end
    _CONFIG = r
    _CONFIG.init = _CONFIG.init or _DEFAULT_CONFIG.init
  end
end


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


-- Launch init --
logger.log("Launching init from", _CONFIG.init)
local handle, err = bootfs.open(_CONFIG.init)
if not handle then
  freeze("File not found:", err)
end
local data = ""
repeat
  local chunk = bootfs.read(handle, math.huge)
  data = data .. (chunk or "")
until not chunk
bootfs.close(handle)
local ok, err = load(data, "=" .. _CONFIG.init, "t", _G)
if not ok then
  freeze(err)
end
local s, r = pcall(ok())
if not s then
  freeze(r)
end

