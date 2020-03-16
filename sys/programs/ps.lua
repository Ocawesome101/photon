-- ps: list active processes --

local shell = require("shell")
local text = require("text")
local sched = require("sched")

local args, opts = shell.parse(...)

local processes = sched.processes()

print(string.format("%s%s%s", "PID  ", "TIME   ", "NAME"))

for i=1, #processes, 1 do
  local info = sched.info(processes[i])
  print(string.format("%s%s%s", text.padRight(tostring(info.pid), 5), text.padRight(tostring(info.uptime):sub(1, 6), 7), info.name))
end
