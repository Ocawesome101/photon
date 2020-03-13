-- Init system --

local _ = {...}
local logger, userspace = _[1], _[2]
local fs = drivers.filesystem

logger.prefix = "Proton Init: "
userspace.sandbox = userspace.sandbox or true

logger.log("Started")

local init_config = {
  scripts = {
    {name = "drivers", file = "/sys/core/drivers.lua"},
    {name = "io", file = "/sys/core/io.lua"},
    {name = "userspace", file = "/sys/core/userspace.lua"}
  },
  daemons = {}
}

function _G.loadfile(file, mode, env, prefix)
  local handle, err = fs.open(file)
  if not handle then
    return nil, err
  end
  
end

local handle = fs.open("/sys/init.cfg", "r")
if handle then
  local c = ""
  repeat
    local _c = handle.read(handle, math.huge)
    c = c .. (_c or "")
  until not _c
  handle.close()
  local ok, err = load("return " .. c, "=/sys/init.cfg", "t", {})
  if ok then
    local s, r = pcall(ok)
    if s then
      init_config = r
    end
  end
end

for _, script in ipairs(init_config.scripts) do
  logger.log("Running script", script.name)
  local ok, err = loadfile(script.file)
  if not ok then
    logger.log("WARN:", err)
  else
    xpcall(ok, function(...)logger.log("WARN:", ...)end)
  end
end

while true do
  coroutine.yield()
end
