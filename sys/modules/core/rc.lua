-- service management --

local rc = {}

local sched = require("sched")
local fs = require("drivers").loadDriver("filesystem")

local pat = "/sys/services/"

local running = {}

local function update()
  for i=1,  #running, 1 do
    if not sched.info(running[i]) then
      running[i] = nil
    end
  end
end

function rc.start(svc)
  checkArg(1, svc, "string")
  if not fs.exists(pat .. svc .. ".lua") then
    return false, svc .. ": Service not found"
  end
  if running[svc] then
    return false, svc .. ": Service is already running"
  end
  local ok, err = loadfile(pat .. svc .. ".lua")
  if not ok then
    return false, svc .. ": " .. err
  end
  running[svc] = sched.spawn(ok, svc)
  update()
  return true
end

function rc.stop(svc)
  checkArg(1, svc, "string")
  if not running[svc] then
    return false, svc .. ": Service is not running"
  end
  sched.kill(running[svc])
  running[svc] = nil
  update()
end

function rc.restart(svc)
  local ok, err = rc.stop(svc)
  if not ok then
    return false, err
  end
  ok, err = rc.start(svc)
  if not ok then
    return false, err
  end
  return true
end

function rc.enable(svc)
  checkArg(1, svc, "string")
  local cfg = require("config").load("/sys/config/rc.cfg")
  for _, s in pairs(cfg) do
    if s == svc then
      return false, svc .. ": Service is already enabled"
    end
  end
  local ok, err = rc.start(svc)
  if not ok then
    return false, err
  end
  cfg[#cfg + 1] = svc
  require("config").save("/sys/config/rc.cfg", cfg)
end

function rc.disable(svc)
  checkArg(1, svc, "string")
  local cfg = require("config").load("/sys/config/rc.cfg")
  for i, s in pairs(cfg) do
    if s == svc then
      table.remove(cfg, i)
      rc.stop(svc)
      require("config").save("/sys/config/rc.cfg", cfg)
      return true
    end
  end
  return false, svc .. ": Service is not enabled"
end

return rc
