-- GPU driver --

local component = ...

local gpus = {}
local screens = {}
local gpu

local boundGPU = 1
local boundScreen = 1

for addr, _ in component.list("gpu") do
  gpus[#gpus + 1] = addr
end
setmetatable(gpus, {__index = function(tbl, key)for k,v in pairs(tbl) do if v == key then return k end end end})

for addr, _ in component.list("screen") do
  screens[#screens + 1] = addr
end
setmetatable(screens, {__index = function(tbl, key)for k,v in pairs(tbl) do if v == key then return k end end end})

if not gpus[boundGPU] then
  boundGPU = 1
end

if not screens[boundScreen] then
  boundScreen = 1
end

gpu = component.proxy(gpus[boundGPU])

function gpu.getCurrent()
  return gpus[gpu.address]
end

function gpu.setCurrent(num)
  checkArg(1, num, "number")
  if not gpus[num] then
    return nil, "No such GPU"
  end
  boundGPU = num
  gpu = component.proxy(gpus[boundGPU])
end

function gpu.setScreen(num)
  checkArg(1, num, "number")
  if not screens[num] then
    return nil, "No such screen"
  end
  boundScreen = num
  gpu.bind(screens[boundScreen])
end

function gpu.available() -- Get all available GPUs
  return gpus
end

function gpu.isAvailable()
  if #gpus > 0 and #screens > 0 then
    return true
  else
    return false
  end
end

return gpu
