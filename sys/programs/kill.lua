-- kill: kill processes --

local shell = require("shell")
local sched = require("sched")

local args, opts = shell.parse(...)

if #args < 1 then
  error("usage: kill PID")
end

if not tonumber(args[1]) then
  error("Invalid PID")
end

local ok, err = sched.kill(tonumber(args[1]))
if not ok and err then error(err) end
