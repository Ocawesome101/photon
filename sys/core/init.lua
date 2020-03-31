-- Init system --

local start = computer.uptime()
local logger = ...
local fs = component.proxy(computer.getBootAddress())

logger.prefix = "Photon Init:"

function os.initStartupTime()
  return start
end

logger.log("Started")

-- Available types are:
--   script: runs once, intended to initialize APIs
--   daemon: runs in background
local init_config = {
  {type = "script", name = "drivers", file = "/sys/core/drivers.lua"},
  {type = "script", name = "io", file = "/sys/core/io.lua"},
  {type = "script", name = "package", file = "/sys/core/package.lua"},
  {type = "daemon", name = "inputd", file = "/sys/services/inputd.lua"},
  {type = "script", name = "userspace", file = "/sys/core/userspace.lua"}
}

function _G.loadfile(file, mode, env, prefix)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  checkArg(3, env, "table", "nil")
  checkArg(4, prefix, "string", "nil")
  local mode = mode or "t"
  local env = env or _G
  local prefix = prefix or ""
  local handle, err = fs.open(file)
  if not handle then
    return nil, err
  end
  
  local data = ""
  repeat
    local chunk = fs.read(handle, math.huge)
    data = data .. (chunk or "")
  until not chunk
  
  fs.close(handle)
  return load(prefix .. data, "=" .. file, mode, env)
end

local ok, err = loadfile("/sys/config/init.cfg", "t", {}, "return ")
if ok then
  local s, r = pcall(ok)
  if s then
    init_config = r
  end
end

local sched = sched or require("sched")
local drivers = drivers or require("drivers")
local gpu = (drivers.loadDriver and drivers.loadDriver("gpu")) or component.proxy(component.list("gpu")())

local function panic(...)
  local computer = computer or require("computer")
  local msg = table.concat({"PANIC:", ...})
  local trace = debug.traceback(msg)
  local y = 1
  gpu.setForeground(0x000000)
  gpu.setBackground(0xFFFFFF)
  for line in trace:gmatch("^\n+") do
    gpu.set(1, y, line)
  end
  for _, pid in pairs(sched.processes()) do
    if pid ~= 1 then
      sched.kill(pid)
    end
  end
  while true do
    computer.beep(500, 1)
  end
end

for _, item in ipairs(init_config) do
  local ok, err = loadfile(item.file)
  if not ok then
    error(item.file .. ":" .. err)
  else
    logger.log("Running startup script:", item.name)
    ok(logger)
  end
end

while true do
  coroutine.yield()
end
