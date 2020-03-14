-- P-Kernel, the heart of Proton --

local _BUILD_ID = "b733621"
local _KERNEL_NAME = "Proton"
function os.build()
  return _BUILD_ID
end
function os.uname()
  return _KERNEL_NAME
end

-- Boot filesystem proxy, for loading drivers. --
local addr = computer.getBootAddress()
local bootfs = component.proxy(addr)


-- Logging --
local logger = {}
local ps = computer.pullSignal
do
  local invoke = component.invoke
  logger.log = function()end
  logger.prefix = _KERNEL_NAME .. ":"
  local gpu = component.list("gpu")()
  local screen = component.list("screen")()
  if gpu and screen then
    invoke(gpu, "bind", screen)
    local y = 1
    local w, h = invoke(gpu, "maxResolution")
    invoke(gpu, "setResolution", w, h)
    invoke(gpu, "fill", 1, 1, w, h, " ")
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
    ps()
  end
end

logger.log("Initializing")
logger.log("Kernel revision:", _BUILD_ID)

-- Load kernel configuration from /kernel.cfg --
local _DEFAULT_CONFIG = {drivers = {"filesystem","logger","user_io","internet"},init="/sys/core/init.lua"}
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


-- Task scheduler --
logger.log("Initializing scheduler")
do
  local sched = {}
  
  local ps, uptime = computer.pullSignal, computer.uptime
  local create, status, resume, yield = coroutine.create, coroutine.status, coroutine.resume, coroutine.yield
  
  local processes = {}
  local currentpid = 0
  local pid = 1
  local sleeptimeout = _CONFIG.process_timeout or 0.05
  
  local signals = {}
  local function autosleep()
    local sig = {ps(sleeptineout)}
    if #sig > 0 then
      signals[#signals + 1] = sig
    end
  end
  
  local function autokill()
    local dead = {}
    for _, process in pairs(processes) do
      if process.dead or dead[process.parent] or status(process.coro) == "dead" then
        dead[process.pid] = true
        process.dead = true
      end
    end
    for pid, _ in pairs(dead) do
      processes[pid] = nil
    end
  end
  
  local function handleError(pid, err)
    logger.log("Handling", err, pid)
    local handler = processes[pid].handler
    if not handler or type(handler) ~= "function" then
      if not processes[processes[pid].parent] then
        return error(err)
      else
        return handleError(processes[pid].parent, err)
      end
    end
    return handler(err)
  end
  
  sched.signals = {
    resume = 1,
    event = 2,
    ipc = 3,
    kill = 4,
    user = 5
  }

  function sched.spawn(func, name, handler)
    checkArg(1, func, "function")
    checkArg(2, name, "string")
    checkArg(2, handler, "function", "nil")
    local ps = {
      coro = create(func),
      name = name,
      handler = handler or error,
      pid = pid,
      parent = currentpid,
      ipc_buffer = {},
      dead = false,
      running = false,
      started = false,
      starttime = uptime(),
      runtime = 0,
      sig = 0
    }
    processes[pid] = ps

    pid = pid + 1
    return pid - 1
  end

  function sched.send_ipc(pid, ...)
    checkArg(1, pid, "number")
    for _, process in pairs(processes) do
      if process.pid == pid then
        process.ipc_buffer[#process.ipc_buffer + 1] = {...}
      end
    end
  end
  
  function sched.send_signal(pid, signal)
    checkArg(1, pid, "number")
    checkArg(2, signal, "number")
    for _, process in pairs(processes) do
      if process.pid == pid then
        process.sig = signal
      end
    end
  end
  
  function sched.kill(pid)
    checkArg(1, pid, "number")
    for _, process in pairs(processes) do
      if process.pid == pid then
        process.dead = true
      end
    end
    autokill()
  end
  
  function sched.start()
    sched.start = nil
    while #processes > 0 do
      for pid, _ in pairs(processes) do
        processes[pid].runtime = uptime() - processes[pid].starttime
        processes[pid].started = true
        processes[pid].running = true
        local sig = {}
        if #signals > 0 then
          sig = signals[1]
          table.remove(signals, 1)
        end
        local ok, ret
        if #sig > 0 then
          ok, ret = resume(processes[pid].coro, sched.signals.event, table.unpack(sig))
        elseif #processes[pid].ipc_buffer > 0 then
          local ipc = processes[pid].ipc_buffer[1]
          table.remove(processes[pid].ipc_buffer, 1)
          ok, ret = resume(processes[pid].coro, sched.signals.ipc, table.unpack(ipc))
        elseif processes[pid].sig > 0 then
          local psig = processes[pid].sig
          processes[pid].sig = nil
          ok, ret = resume(processes[pid].coro, psig)
        else
          ok, ret = resume(processes[pid].coro, sched.signals.resume)
        end
        if not ok and ret then
          processes[pid].dead = true
          processes[pid].running = false
          handleError(pid, ret)
        end
      end
      autokill()
      autosleep()
    end
    logger.log("All processes died")
  end
  
  function computer.pullSignal()
    yield()
  end
  
  _G.sched = sched
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
local s, r = sched.spawn(function()return ok(logger)end, "init", freeze)
if not s then
  freeze(r)
end
sched.start()

