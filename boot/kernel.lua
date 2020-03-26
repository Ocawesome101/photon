-- P-Kernel, the heart of Photon --

local _KERNEL_START = computer.uptime()
local _BUILD_ID = "110a4c4"
local _KERNEL_NAME = "Photon"
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
local _DEFAULT_CONFIG = {drivers = {"filesystem"},init="/sys/core/init.lua"}
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


-- Task scheduler --
logger.log("Initializing scheduler")
do
  local sched = {}
  
  local ps, uptime = computer.pullSignal, computer.uptime
  local create, status, resume, yield = coroutine.create, coroutine.status, coroutine.resume, coroutine.yield
  
  local processes = {}
  local currentpid = 0
  local pid = 1
  local timeout = _CONFIG.process_timeout or 0.05
  
  local signals = {}
  local function autosleep()
    local sig = {ps(timeout)}
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
    checkArg(3, handler, "function", "nil")
    local ps = {
      coro = create(func),
      name = name,
      handler = handler,
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
  end
  
  function sched.current()
    return currentpid
  end
  
  function sched.parent(pid)
    checkArg(1, pid, "number", "nil")
    local pid = pid or currentpid
    
    if not processes[pid] then
      return nil, "No such process"
    end
    
    return processes[pid].parent
  end

  function sched.detach() -- Detach a process from any other processes
    local pid = currentpid
    processes[pid].parent = 0
  end
  
  function sched.processes()
    local proc = {}
    for pid, _ in pairs(processes) do
      proc[#proc + 1] = pid
    end
    return proc
  end
  
  function sched.info(pid)
    checkArg(1, pid, "number", "nil")
    local pid = pid or currentpid

    if not processes[pid] then
      return nil, "No such process"
    end
    
    local proc = processes[pid]
    return {name = proc.name, pid = proc.pid, parent = proc.parent, uptime = proc.runtime, start = proc.starttime, running = proc.running}
  end
  
  function sched.start()
    sched.start = nil
    while #processes > 0 do
      local sig = {}
      if #signals > 0 then
        sig = signals[1]
        table.remove(signals, 1)
      end

      for pid, _ in pairs(processes) do
        currentpid = pid
        local proc = processes[pid]
        proc.runtime = uptime() - proc.starttime
        proc.started = true
        proc.running = true
        local ok, ret
        if #sig > 0 then
          ok, ret = resume(proc.coro, sched.signals.event, table.unpack(sig))
        elseif #proc.ipc_buffer > 0 then
          local ipc = proc.ipc_buffer[1]
          table.remove(proc.ipc_buffer, 1)
          ok, ret = resume(proc.coro, sched.signals.ipc, table.unpack(ipc))
        elseif proc.sig > 0 then
          local psig = proc.sig
          proc.sig = nil
          ok, ret = resume(proc.coro, psig)
        else
          ok, ret = resume(proc.coro, sched.signals.resume)
        end
        if not ok and ret then
          proc.dead = true
          proc.running = false
          handleError(pid, ret)
        end
      end
      autokill()
      autosleep()
    end
    logger.log("PANIC: INIT PROCESS DIED")
    for line in debug.traceback():gsub("\t", "    "):gmatch("[^\n]+") do
      logger.log(line)
    end
  end
  
  _G.sched = sched
end


-- Set up the userspace sandbox

local userspace = {
  _OSVERSION = string.format("%s build %s", os.uname(), os.build()),
  assert = assert,
  error = error,
  getmetatable = getmetatable,
  ipairs = ipairs,
  load = load,
  next = next,
  pairs = pairs,
  pcall = pcall,
  rawequal = rawequal,
  rawget = rawget,
  rawlen = rawlen,
  rawset = rawset,
  select = select,
  setmetatable = setmetatable,
  tonumber = tonumber,
  tostring = tostring,
  type = type,
  xpcall = xpcall,
  checkArg = checkArg,
  bit32 = setmetatable({}, {__index=bit32}),
  debug = setmetatable({}, {__index=debug}),
  math = setmetatable({}, {__index=math}),
  os = setmetatable({}, {__index=os}),
  string = setmetatable({}, {__index=string}),
  table = setmetatable({}, {__index=table}),
  drivers = setmetatable({}, {__index=drivers}),
  sched = setmetatable({}, {__index=sched}),
  computer = setmetatable({}, {__index=computer}),
  unicode = setmetatable({}, {__index=unicode}),
  component = setmetatable({}, {__index=component}),
  coroutine = {
    yield = coroutine.yield
  }
}

userspace._G = userspace


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
local ok, err = load(data, "=" .. _CONFIG.init, "t", userspace)
if not ok then
  freeze(err)
end
local s, r = sched.spawn(function()return ok(logger)end, "init", freeze)
if not s then
  freeze(r)
end
local _STARTUP_TIME = computer.uptime() - _KERNEL_START
function os.kernelStartupTime()
  return _STARTUP_TIME
end
sched.start()

