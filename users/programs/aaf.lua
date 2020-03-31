-- AAF parser --

local shell = require("shell")
local sound = require("drivers").loadDriver("sound")

local args, opts = shell.parse(...)

local card = "noise"

local function playNote(chan, freq, dur)
--  print(freq)
  if card == "noise" then
    sound.noise.play({[chan]={freq, dur}})
  elseif card == "sound" then
    sound.sound.setFrequency(chan, freq)
    sound.sound.delay(dur)
  else
    sound.beep.beep({[freq]=dur})
  end
end

local function setVolume(chan, vol)
  sound.sound.setVolume(chan, vol)
end

local function changeASDR(chan, attack, delay, sust, rel)
  sound.sound.setASDR(chan, attack, delay, sust, rel)
end

local function setWave(chan, wtype)
  if card == "noise" then
    sound.noise.setMode(chan. sound.noise.modes[wtype])
  elseif card == "sound" then
    sound.sound.setWave(chan, sound.sound.modes[wtype])
  else
    error("beep card does not support wavetypes")
  end
end

if #args < 1 then
  io.stderr:write("usage: aaf FILE\n")
  os.exit(1)
end

local handle = io.open(shell.resolve(args[1]), "r")
local sig = handle:read(5)
if sig ~= "\x13AAF\x03" then
  error("invalid signature")
end

local waveType = handle:read(1)
local misc = handle:read(1)
local channels = handle:read(1):byte()
local waves = {
  [0] = "square",
  [1] = "sine",
  [2] = "triangle",
  [3] = "sawtooth"
}

local sunpack = function(pat, dat)
  if dat == nil then
    return nil
  else
    return string.unpack(pat, dat)
  end
end

card = args[2] or "noise"

local exit = false
while true do
  for i=1, channels, 1 do
    local freq = sunpack(">I2", handle:read(2))
    if not freq then exit = true break end
    if freq == 1 then -- ASDR
      local attack = sunpack(">I2", handle:read(2))
      local delay = sunpack(">I2", handle:read(2))
      local sustain = sunpack(">I2", handle:read(2))
      local release = sunpack(">I2", handle:read(2))
      changeASDR(i, attack, delay, sustain, release)
    elseif freq == 2 then -- volume
      local vol = sunpack(">I2", handle:read(2))
      setVolume(i, vol/255)
    elseif freq == 3 then -- wave type
      local wave = sunpack(">I2", handle:read(2))
      setWave(i, waves[wave])
    else
      local dur = sunpack(">I2", handle:read(2))
      print(freq, dur)
      playNote(i, freq, dur / 100)
    end
  end
  if exit then
    break
  end
end

if card == "sound" then
  sound.sound.process()
end

handle:close()
os.exit(0)
