-- ping --

local net = require("net")
local shell = require("shell")

local args, opts = shell.parse(...)

if #args == 0 then
  io.stderr:write("usage: ping HOSTNAME")
  return 1
end

local con, err = net.connect(args[1])

if not con then
  error(err)
end

while true do
  local time, err = con.ping()
  if not time then
    error(err)
  end
  print("Got response in", time)
end
