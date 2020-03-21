-- cat: print contents of a file --

local shell = require("shell")
local computer = require("computer")

local args, opts = shell.parse(...)

if #args == 0 or args[1] == "-" then
  while true do
    io.write(io.read())
  end
end

for i=1, #args, 1 do
  local handle, err = io.open(shell.resolve(args[i]), "r")
  if not handle then
    error(args[i] .. ": " .. err)
  end
  local data = handle:read("a")
  handle:close()
  print(data)
end
