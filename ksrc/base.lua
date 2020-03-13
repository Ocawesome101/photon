-- P-Kernel, the heart of Proton --

local _BUILD_ID = "$[[git rev-parse --short HEAD]]"
local _KERNEL_NAME = "Proton"
function os.build()
  return _BUILD_ID
end
function os.uname()
  return _KERNEL_NAME
end
--#include "kmod/bootfs.lua"
--#include "kmod/logger.lua"
logger.log("Initializing")
logger.log("Kernel revision:", _BUILD_ID)
--#include "kmod/config.lua"
--#include "kmod/drivers.lua"
--#include "kmod/scheduler.lua"
--#include "kmod/init.lua"
