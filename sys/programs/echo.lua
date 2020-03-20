-- echo: echo clone --

local shell = require("shell")

local args, opts = shell.parse(...)

local notrail = opts.n

local str = table.concat(args, " ")
str = str:gmatch("[^\n]+")()

io.write(str)

if not notrail then
  io.write("\n")
end
