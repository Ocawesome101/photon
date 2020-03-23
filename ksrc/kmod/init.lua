-- Launch init --
logger.log("Launching init from", _CONFIG.init)
local handle, err = bootfs.open(_CONFIG.init)
if not handle then
  freeze("File not found:", err)
end
local data = ""
repeat
  local chunk = bootfs.read(handle, math.huge)
  data = data .. (chunk or "")
until not chunk
bootfs.close(handle)
local ok, err = load(data, "=" .. _CONFIG.init, "t", userspace)
if not ok then
  freeze(err)
end
local s, r = sched.spawn(function()return ok(logger)end, "init", freeze)
if not s then
  freeze(r)
end
local _STARTUP_TIME = computer.uptime() - _KERNEL_START
function os.kernelStartupTime()
  return _STARTUP_TIME
end
sched.start()
