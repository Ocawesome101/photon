-- blink the cursor --

local sched = require("sched")
sched.detach()
sched.unregister("interrupt")

local term = require("term")

while true do
  os.sleep(0.7)
  term.setCursorBlink((not term.getCursorBlink()))
end
