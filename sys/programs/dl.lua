-- Equivalent of wget --

local shell = require("shell")
local internet = require("drivers").loadDriver("internet")
local fs = require("drivers").loadDriver("filesystem")

local args, opts = shell.parse(...)

if #args < 1 then
  io.stderr:write("usage: dl [--out[put]=file] URL\n")
  return 1
end

local out = opts.out or opts.output or fs.name(args[1])

local handle, err = internet.get(args[1])
if not handle then
  error(err)
end

local output = io.open(shell.resolve(out), "w")
repeat
  local c = handle.read(math.huge)
  output:write((c or ""))
until not c

handle.close()
output:close()
