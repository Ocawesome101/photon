-- set: set/get shell variables --

local shell = require("shell")

local args, opts = shell.parse(...)

if #args == 0 then
  local vars = os.getenv() -- calling this with no args will return all current env-vars
  for _,var in ipairs(vars) do
    print(("%s=\"%s\""):format(var, os.getenv(var)))
  end
else
  os.setenv(args[1], (args[2] or ""))
end
