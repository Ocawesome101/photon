-- echo: echo clone --

local shell = require("shell")
local term = require("term")

local args, opts = shell.parse(...)

local notrail = opts.n

local str = table.concat(args, " ")
str = str:gmatch("[^\n]+")()

term.write(str)

if not notrail then
  term.write("\n")
end
