-- OAF parser. Requires a Computronics noise card --

local shell = require("shell")
local sound = require("drivers").loadDriver("sound")

local args, opts = shell.parse(...)

if #args == 0 then
  io.stderr:write("Usage: oaf FILE\n")
  return 1
end

local handle, err = io.open(shell.resolve(args[1]))
if not handle then
  error(err)
end
local raw = handle:read("a")
handle:close()

local function parse(bytes)
  local toPlay = {}
  for i=1, #bytes, 2 do
    local f = string.unpack("H", bytes:sub(i, i + 2))
    if f ~= 0 then
      toPlay[f] = 0.1
      print(f)
    end
  end
  sound.beep.beep(toPlay)
  os.sleep(0.1)
end

for chunk in raw:gmatch("................") do
  parse(chunk)
end
