-- play the Tetris theme! --

local b = require("drivers").loadDriver("sound").beep
local event = require("event")

local t = {
  e = 659,
  b = 494,
  c = 523,
  d = 587,
  a = 440,
  f = 698,
  A = 880,
  g = 784
}

local function one()
  b.beep({[t.e] = 0.5})
  os.sleep(0.45)
  b.beep({[t.b] = 0.25})
  os.sleep(0.2)
  b.beep({[t.c] = 0.25})
  os.sleep(0.2)
  b.beep({[t.d] = 0.5})
  os.sleep(0.45)
  b.beep({[t.c] = 0.25})
  os.sleep(0.2)
  b.beep({[t.b] = 0.25})
  os.sleep(0.2)
  b.beep({[t.a] = 0.5})
  os.sleep(0.55)
  b.beep({[t.a] = 0.25})
  os.sleep(0.2)
  b.beep({[t.c] = 0.25})
  os.sleep(0.2)
  b.beep({[t.e] = 0.5})
  os.sleep(0.45)
  b.beep({[t.d] = 0.25})
  os.sleep(0.25)
  b.beep({[t.c] = 0.25})
  os.sleep(0.25)
  b.beep({[t.b] = 0.5})
  os.sleep(0.55)
  b.beep({[t.b] = 0.25})
  os.sleep(0.2)
  b.beep({[t.c] = 0.25})
  os.sleep(0.2)
  b.beep({[t.d] = 0.5})
  os.sleep(0.45)
  b.beep({[t.e] = 0.5})
  os.sleep(0.45)
  b.beep({[t.c] = 0.5})
  os.sleep(0.45)
  b.beep({[t.a] = 0.5})
  os.sleep(0.55)
  b.beep({[t.a] = 0.5})
  os.sleep(0.6)
  b.beep({[t.d] = 0.5})
  os.sleep(0.45)
  b.beep({[t.f] = 0.25})
  os.sleep(0.2)
  b.beep({[t.A] = 0.5})
  os.sleep(0.45)
  b.beep({[t.g] = 0.25})
  os.sleep(0.2)
  b.beep({[t.f] = 0.25})
  os.sleep(0.2)
  b.beep({[t.e] = 0.75})
  os.sleep(0.7)
  b.beep({[t.c] = 0.25})
  os.sleep(0.2)
  b.beep({[t.e] = 0.50})
  os.sleep(0.45)
  b.beep({[t.d] = 0.25})
  os.sleep(0.2)
  b.beep({[t.c] = 0.25})
  os.sleep(0.2)
  b.beep({[t.b] = 0.5})
  os.sleep(0.55)
  b.beep({[t.b] = 0.25})
  os.sleep(0.2)
  b.beep({[t.c] = 0.25})
  os.sleep(0.2)
  b.beep({[t.d] = 0.5})
  os.sleep(0.45)
  b.beep({[t.e] = 0.5})
  os.sleep(0.45)
end

local function two()
end

one()
two()
