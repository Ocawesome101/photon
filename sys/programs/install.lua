-- Installer --

local shell = require("shell")
local fs = require("drivers").loadDriver("filesystem")
local prompts = require("prompts")

local args, opts = shell.parse(...)

local inst = {}
local targets = {}
local addrs = {}

local root = fs.get("/")
if not root then
  error("No rootfs, aborting")
end

for k, v in pairs(fs.mounts()) do
  if fs.get(v.path).exists(".installinfo") then
    inst[#inst + 1] = v.address
    addrs[v.address] = v.path
  else
    targets[#targets + 1] = v.address
    addrs[v.address] = v.path
  end
end

local install = prompts.choice("What do you want to install?", inst)
local target
if #targets == 0 then
  target = rootfs
else
  target = prompts.choice("To where do you want to install?", targets)
end

shell.execute("cp -rv ", addrs[install], addrs[target])

local yn = prompts.yesno("Installation complete. Reboot now?", "y")

if yn then
  require("computer").shutdown(true)
else
  print("Have a nice day.")
  return 0
end
