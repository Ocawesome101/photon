-- netcopy: copy a file over the network --

local net = require("net")

local args = {...}

local con, err = net.connect(args[1])
if not con then
  error(err)
end

print("Sending", args[2], "to", args[1] .. ":" .. args[3] or args[2])
con.send(args[2], args[3] or args[2])
