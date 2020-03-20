-- right-click menu --

local modwm = require("modwm")
local computer = require("computer")

local args = {...}
local tlx,tly = args[1], args[2]

local canvas = modwm.createWindow(tlx, tly, 10, 10, "Menu")

canvas:fill(1, 1, 10, 10, " ", 0x000000, 0xCCCCCC)
canvas:set(1, 10, "Exit")

while true do
  local sig, event, clickX, clickY, button = computer.pullSignal()
  if event == "touch" then
    if button == 0 and clickX >= tlx and clickX <= tlx+10 and clickY == tly+10 then
      canvas:set(1, 10, "Exit      ", 0xFFFFFF, 0x000000)
      coroutine.yield()
      sched.send_signal(sched.parent(), sched.signals.kill)
      coroutine.yield()
      sched.kill(sched.current())
    elseif clickX < tlx or clickX >= tlx+10 or clickY < tly or clickY > tly+10 then
      sched.kill(sched.current())
      coroutine.yield()
    end
  end
end
