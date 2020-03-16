-- power management --

local shell = require("shell")
local computer = require("computer")

local args, opts = shell.parse(...)

if opts.r then
  computer.shutdown(true)
elseif opts.s then
  computer.shutdown(false)
else
  error("usage: power -s|-r", 0)
end
