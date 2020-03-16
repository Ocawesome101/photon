-- print free memory --

local shell = require("shell")
local computer = require("computer")

local _, opts = shell.parse(...)

local readable = opts.h or false

local total = computer.totalMemory()
local free = 0
for i=1, 32, 1 do -- give the GC a chance!
  free = computer.freeMemory()
end
local used = total - free

if readable then
  total = tostring(math.floor(total/1024)) .. "." .. tostring(total % 1024):sub(1,2) .. "k"
  free = tostring(math.floor(free/1024)) ..  "." .. tostring(free % 1024):sub(1,2) .. "k"
  used = tostring(math.floor(used/1024)) .. "." .. tostring(used % 1024):sub(1,2) .. "k"
  print(("Total: %s\nUsed: %s\nFree: %s"):format(total, used, free))
else
  total = math.floor(total)
  free = math.floor(free)
  used = math.floor(used)
  print(("Total: %d\nUsed: %d\nFree: %d"):format(total, used, free))
end
