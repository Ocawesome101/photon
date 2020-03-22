-- blink the cursor --

local term = require("term")

while true do
  os.sleep(0.7)
  term.setCursorBlink((not term.getCursorBlink()))
end
