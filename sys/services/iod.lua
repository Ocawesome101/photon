-- Literally just writes things to stdout --

local computer = require("computer")
local unicode = require("unicode")

local pcio = true

function computer.setIO(bool)
  checkArg(1, bool, "boolean")
  pcio = bool
end

function computer.getIO()
  return pcio
end

local buffer = ""

while true do
  local sig, e, _, id, code = computer.pullSignal()
  if e == "key_down" and pcio then -- Keyboard input can be disabled
    io.write(unicode.char(id))
  end
end
