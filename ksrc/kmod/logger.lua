-- Logging --
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
    local y = 1
    local w, h = invoke(gpu, "maxResolution")
    invoke(gpu, "setResolution", w, h)
    invoke(gpu, "fill", 1, 1, w, h, " ")
    logger.log = function(...)
      local msg = table.concat({logger.prefix, ...}, " ")
      invoke(gpu, "set", 1, y, msg)
      if y < h then
        y = y + 1
      else
        invoke(gpu, "copy", 1, 1, w, h, 0, -1)
        invoke(gpu, "fill", 1, h, w, 1, " ")
      end
    end
  end
end
local function freeze(...)
  logger.log("ERR:", ...)
  while true do
    ps()
  end
end
