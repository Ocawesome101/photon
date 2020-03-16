-- Init system --

local logger = ...
local fs = drivers.filesystem

logger.prefix = "Proton Init:"

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

local fs = drivers.filesystem
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
    local chunk = handle.read(math.huge)
    data = data .. (chunk or "")
  until not chunk
  
  handle.close()
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

for _, item in ipairs(init_config) do
  local ok, err = loadfile(item.file)
  if not ok then
    logger.log("ERR:", item.file .. ":", err)
  else
    if item.type == "script" then
      logger.log("Running startup script:", item.name)
      xpcall(function()return ok(logger)end, function(...)logger.log("ERR:", ...)end)
    elseif item.type == "daemon" then
      logger.log("Starting service:", item.name)
      sched.spawn(function()return ok(logger)end, item.name)
    end
  end
end

while true do
  coroutine.yield()
end
