-- mountd: Automatically mount/unmount filesystems --

local fs = require("drivers").loadDriver("filesystem")
local computer = require("computer")
local signals = require("signals")

while true do
  local signal, event, address, componenttype = computer.pullSignal()
  if signal == signals.event then
    if componenttype == "filesystem" then
      if event == "component_added" then
        fs.mount(address)
      elseif event == "component_removed" then
        fs.umount(address)
      end
    end
  end
end
