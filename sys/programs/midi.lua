-- MIDI parser. Requires a Computronics noise card --

local shell = require("shell")
local sound = require("drivers").loadDriver("sound")

local args, opts = shell.parse(...)

if #args == 0 then
  io.stderr:write("Usage: midi FILE\n")
  return 1
end

local handle, err = io.open(args[1])
if not handle then
  error(err)
end
local raw = handle:read("a")
handle:close()

-- Files are split into four-byte segments, with each segment split as follows:
-- Byte 1: Waveform (first two bits), channel (1-8, next 3 bits), 3 unused
-- Byte 2-3: Frequency
-- Byte 4: Duration * 0.1 sec
local function parse(bytes)
  local freq = (bytes:sub(2,2):byte() >> 8) + bytes:sub(3,3):byte() + 1
  local byte = bytes:sub(1,1):byte()
  local wave = (byte >> 6) + 1
  local chan = (byte & 0x1C) + 1
  local dur = bytes:sub(4,4):byte()
  print(wave, chan, freq, dur)
  sound.noise.setMode(chan, wave)
  sound.noise.play({{freq, dur * 0.1}})
end

for chunk in raw:gmatch("....") do
  parse(chunk)
end
