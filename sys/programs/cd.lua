-- cd --

local shell = require("shell")
local fs = require("drivers").loadDriver("filesystem")

local args, opts = shell.parse(...)

if #args == 0 then
  shell.setWorkingDirectory(os.getenv("HOME"))
else
  local dir = shell.resolve(args[1])
  if not fs.exists(dir) then
    error(args[1] .. ": no such directory")
  end
  if not fs.isDirectory(dir) then
    error(args[1] .. ": not a directory")
  end

  shell.setWorkingDirectory(dir)
end
