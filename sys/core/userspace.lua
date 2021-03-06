-- Finish userspace --

local logger = ...

logger.prefix = "Photon Userspace:"
local drivers = require("drivers")
local fs = drivers.loadDriver("filesystem")
local sched = require("sched")
local computer = require("computer")

function _G.print(...)
  local args = {...}
  for i=1, #args, 1 do
    args[i] = tostring(args[i])
    io.write(args[i])
    if i < #args then
      io.write(" ")
    end
  end
  io.write("\n")
end

function _G.loadfile(file, mode, env)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  checkArg(3, env, "table", "nil")
  local mode = mode or "bt"
  local env = env or _G
  
  local handle, err = io.open(file, "r")
  if not handle then
    return nil, err
  end
  local data = handle:read("a")
  handle:close()
  
  local ok, err = load(data, "=" .. file, mode, env)
  if not ok then
    return nil, err
  end
  return ok
end

function package.loaded.computer.pullSignal()
  return coroutine.yield()
end

local shell = "/sys/programs/shell.lua"
local handle = io.open("/sys/config/shell.cfg", "r")
if handle then
  local data = handle:read("a")
  handle:close()
  local ok, err = load("return " .. data, "=/sys/config/shell.cfg", "t", {})
  if ok then
    local s, r = pcall(ok)
    if s then
      shell = (type(r) == "string" and r) or r.shell or shell
    end
  end
end

logger.log("Starting shell")
local ok, err = loadfile((fs.exists(shell) and shell) or "/sys/programs/shell.lua")
if not ok then
  logger.prefix = "SHELL ERROR:"
  logger.log(err)
  computer.beep(400, 1)
  while true do
    computer.pullSignal()
  end
end

local function userspaceError(err, lvl)
  local trace = debug.traceback(err, lvl) .. "\n"
  io.write("ERROR IN THREAD " .. sched.current() .. ": " .. sched.info(sched.current()).name .. "\n")
  io.write(trace)
  sched.kill(sched.current())
end

local initCompletionTime = computer.uptime() - os.initStartupTime()
function os.initStartupTime()
  return initCompletionTime
end

local shellPID
while true do
  coroutine.yield()
  local shellRunning = false
  for _, pid in pairs(sched.processes()) do
--    print(pid, shellPID)
    if pid == shellPID then
      shellRunning = true
    end
  end
--  print(shellRunning)
  if not shellRunning then
    shellPID = sched.spawn(function()return ok(logger)end, "shell", userspaceError)
  end
end
