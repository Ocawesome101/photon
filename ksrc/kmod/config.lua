-- Load kernel configuration from /kernel.cfg --
local _DEFAULT_CONFIG = {drivers = {"filesystem","logger","user_io","internet"},userspace = {sandbox = true},init="/sys/core/init.lua"}
local _CONFIG = {}
local handle = bootfs.open("/boot/kernel.cfg")
if not handle then
  _CONFIG = _DEFAULT_CONFIG
else
  local data = ""
  repeat
    local chunk = bootfs.read(handle, math.huge)
    data = data .. (chunk or "")
  until not chunk
  bootfs.close(handle)
  local ok, err = load("return " ..data, "=/boot/kernel.cfg", "t", {})
  if not ok then
    _CONFIG = _DEFAULT_CONFIG
  else
    local s, r = pcall(ok)
    if not s then
      _CONFIG = _DEFAULT_CONFIG
    end
    _CONFIG = r
    _CONFIG.init = _CONFIG.init or _DEFAULT_CONFIG.init
  end
end
