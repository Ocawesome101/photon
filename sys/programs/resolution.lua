-- res --

local shell = require("shell")
local gpu = require("drivers").loadDriver("gpu")

local args, opts = shell.parse(...)

if #args < 2 or not (tonumber(args[1]) and tonumber(args[2])) then
  print(gpu.getResolution())
  return 0
end

local ok, err = gpu.setResolution(tonumber(args[1]), tonumber(args[2]))
if not ok then error(err) end
