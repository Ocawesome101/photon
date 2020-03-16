-- unset: Unset environment variables --

local shell = require("shell")

local args, opts = shell.parse(...)

for _, var in ipairs(args) do
  os.setenv(var, nil)
end
