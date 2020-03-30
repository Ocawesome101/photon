-- file protection --

local users = require("users")
local fs = require("drivers").loadDriver("filesystem")

local remove, open = fs.remove, fs.open
local protected = {
  "/boot",
  "/sys"
}

local function check(file)
  checkArg(1, file, "string")
  local file = fs.canonical(file)
  for k,v in pairs(protected) do
    if file:sub(1, #v) == v and (users.user() ~= "root" or users.uid() ~= 0) then
      error(file .. " is protected")
    end
  end
end

function fs.remove(f)
  checkArg(1, f, "string")
  check(f)
  return remove(f)
end

function fs.open(f, mode)
  checkArg(1, f, "string")
  checkArg(2, mode, "string")
  if mode == "w" or mode == "rw" then
    check(f)
  end
  return open(f, mode)
end
