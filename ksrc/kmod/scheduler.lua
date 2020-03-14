-- Task scheduler --
logger.log("Initializing scheduler")
do
  local sched = {}
  
  local ps, uptime = computer.pullSignal, computer.uptime
  local create, status, resume, yield = coroutine.create, coroutine.status, coroutine.resume, coroutine.yield
  
  local processes = {}
  local currentpid = 0
  local pid = 1
  local sleeptimeout = _CONFIG.process_timeout or 0.5
  
  local signals = {}
  local function autosleep()
    local sig = {ps()}
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
    autokill()
  end
  
  function sched.current()
    return currentpid
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
        processes[pid].runtime = uptime() - processes[pid].starttime
        processes[pid].started = true
        processes[pid].running = true
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

  _G.sched = sched
end
