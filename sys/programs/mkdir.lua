-- mkdir: make directories --

local shell = require("shell")
local fs = require("drivers").loadDriver("filesystem")

local args, opts = shell.parse(...)

local force = opts.p or false

if #args < 1 then
  error("usage: mkdir [-p] DIR1 DIR2 ...", 0)
end

for i=1, #args, 1 do
  local dir = shell.resolve(args[i])
  if fs.exists(dir) and not force then
    error(args[i] .. ": file already exists", 0)
  end

  fs.makeDirectory(dir)
end
