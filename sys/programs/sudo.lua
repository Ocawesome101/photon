-- sudo --

local users = require("users")

local args = {...}

if #args == 0 then
  io.stderr:write("usage: sudo PROGRAM ARG1 ARG2 ...\n")
  os.exit(1)
end

users.sudo(table.unpack(args))
