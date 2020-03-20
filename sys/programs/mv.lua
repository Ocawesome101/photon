-- mv --

local shell = require("shell")

local args, opts = shell.parse(...)

if #args < 2 then
  error("missing file operand")
end

-- this was the easy way to do it :P
shell.execute("cp -rn", table.unpack(args))
shell.execute("rm -rf", table.unpack(args, 1, #args - 1))
