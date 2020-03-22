-- background service management --

local shell = require("shell")
local rc = require("rc")

local args, opts = shell.parse(...)

if #args < 2 then
  io.stderr:write("Usage: rc <start|stop|restart|enable|disable> <service>\n")
  return 1
end

local op = args[1]
local svc = args[2]

local valid = {
  start = true,
  stop = true,
  restart = true,
  disable = true,
  enable = true
}

if not valid[op] then
  error("Unrecognized option " .. op)
end

local ok, err = rc[op](svc)
if not ok then
  error(err)
end
