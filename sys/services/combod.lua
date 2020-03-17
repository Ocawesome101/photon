-- these services are basically event listeners --

local computer = require("computer")
local pressed = {}

local c = 0x2E
local d = 0x20
local lctrl = 0x1D
local rctrl = 0x9D

while true do
  local sig, e, _, id, code = computer.pullSignal()
  if e == "key_down" then
    pressed[code] = true
    if pressed[lctrl] or pressed[rctrl] then
      if pressed[c] then
        computer.pushSignal("interrupt")
      elseif pressed[d] then
        computer.pushSignal("exit")
      end
    end
  elseif e == "key_up" then
    pressed[code] = nil
  end
end
