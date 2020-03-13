-- Init system --

local _ = {...}
local logger, userspace = _[1], _[2]

logger.prefix = "Proton Init: "
userspace.sandbox = userspace.sandbox or true

logger.log("Started")

local init_config = {
  scripts = {
    {name = "drivers", file = "/sys/core/drivers.lua"},
    {name = "io", file = "/sys/core/io.lua"},
    {name = "userland", file = "/sys/core/userland.lua"}
  },
  daemons = {}
}

local bootfs = component.proxy(computer.getBootAddress())

local handle = bootfs.open("/sys/init.cfg", "r")
if handle then
  local c = ""
  repeat
    local _c = bootfs.read(handle, math.huge)
    c = c .. (_c or "")
  until not _c
  bootfs.close(handle)
  local ok, err = load("return " .. c, "=/sys/init.cfg", "t", {})
  if ok then
    local s, r = pcall(ok)
    if s then
      init_config = r
    end
  end
end

for _, script in ipairs(init_config.scripts) do
  local ok, err = loadfile(script.file)
  if not ok then
    logger.log("WARN:", err)
  end
  ok()
end
