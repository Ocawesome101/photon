-- Finish off the `os` API, mostly --

local sched = require("sched")

local env = {}

function os.setenv(varname, value)
  env[varname] = value
end

function os.getenv(varname)
  return env[varname]
end

function os.difftime(t1, t2)
  return t1 - t2
end

function os.exit(code)
  if code and type(code) == "number" then
    sched.ipc_send(sched.parent(), code)
  end
  sched.kill(sched.current())
end
