-- Graphical boot logging --
local logger = {}
local ps = computer.pullSignal
do
  local invoke = component.invoke
  logger.log = function()end
  logger.prefix = _KERNEL_NAME .. ":"
  local gpu = component.list("gpu")()
  local screen = component.list("screen")()
  if gpu and screen then
    invoke(gpu, "bind", screen)
    local w, h = invoke(gpu, "maxResolution")
    invoke(gpu, "setResolution", w, h)
    local y = 1
    invoke(gpu, "setForeground", 0x000000)
    invoke(gpu, "setBackground", 0xFFFFFF)
    invoke(gpu, "fill", 1, 1, w, h, " ")
    logger.log = function(...)
      local msg = table.concat({logger.prefix, ...}, " ")
      invoke(gpu, "copy", 1, 1, w, h, 0, -1)
      invoke(gpu, "fill", 1, h, w, 1, " ")
      invoke(gpu, "set", 1, h, msg)
      y = y + 1
    end
  end
end
local function freeze(...)
  logger.log("ERR:", ...)
  while true do
    ps()
  end
end
