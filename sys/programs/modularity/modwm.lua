-- window manager --

local signals = require("signals")
local sched = require("sched")
local modwm = require("modwm")
local computer = require("computer")

local desktop_menu = loadfile("/sys/programs/modularity/rightclick_menu.lua")

while true do
  modwm.redraw()
  local sig, e, p, x, y, button = computer.pullSignal()
  if sig == signals.event then
    if e == "touch" then
      if button == 1 then
        sched.spawn(function()desktop_menu(x,y)end, "Desktop menu")
      end
    end
  end
end
