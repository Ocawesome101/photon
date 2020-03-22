-- rc-start configured services --

local rc = require("rc")
local config = require("config")

local cfg = config.load("/sys/config/rc.cfg")
if not cfg then
  return
end

for _, service in pairs(cfg) do
  rc.start(service)
end
