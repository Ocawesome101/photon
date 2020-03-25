-- blink the cursor --

require("sched").detach()

local term = require("term")

while true do
  os.sleep(0.7)
  term.setCursorBlink((not term.getCursorBlink()))
end
