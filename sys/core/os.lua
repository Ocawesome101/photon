-- Finish off the `os` API, mostly --

local sched = require("sched")
local computer = require("computer")

local env = {
  HOSTNAME = "photon"
}

function os.setenv(varname, value)
  checkArg(1, varname, "string")
  env[varname] = value
end

function os.getenv(varname)
  checkArg(1, varname, "string", "nil")
  if not varname then
    local r = {}
    for k,v in pairs(env) do
      r[#r+1] = k
    end
    return r
  else
    return env[varname]
  end
end

function os.difftime(t1, t2)
  return t1 - t2
end

function os.exit(code)
  if code and type(code) == "number" then
    sched.send_ipc(sched.parent(), code)
  end
  sched.kill(sched.current())
end

function os.sleep(time)
  local start = computer.uptime()
  local dest = start + time
  repeat
    computer.pullSignal()
  until computer.uptime() >= dest
end
