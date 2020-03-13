-- Task scheduler --
do
  _G.sched = {}
  
  local computer, coroutine = computer, coroutine
  
  local processes = {}
  local currentpid = 0
  local pid = 1
  
  local signals = {}
  local function autosleep()
  end
  
  local function autokill()
    local dead = {}
    for _, process in pairs(processes) do
      
  end
  
  function sched.spawn(func, name, handler)
    processes[#processes + 1] = {
      coro = coroutine.create(func),
      name = name,
      handler = handler or error,
      pid = pid,
      parent = currentpid,
      ipc_buffer = {},
      dead = false,
      started = false,
      starttime = computer.uptime()
      runtime = 0
    }

    pid = pid + 1
    return pid - 1
  end
  
  function sched.ipc_send(pid, ...)
    checkArg(1, pid, "number")
    for _, process in pairs(processes)
  end
  
  function sched.start()
    while #processes > 0 do
      for _, process in pairs(processes) do
      end
      autokill()
      autosleep()
    end
  end
end
