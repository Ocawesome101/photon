-- Installer --

local shell = require("shell")
local fs = require("drivers").loadDriver("filesystem")

local args, opts = shell.parse(...)

local installable = {}

for k, v in pairs(mts) do
  if fs.exists()
end
