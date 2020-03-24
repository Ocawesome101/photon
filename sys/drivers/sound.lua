-- Generic Computronics sound card driver --

local component = ...

local sound_component = component.list("sound")()
local beep_component = component.list("beep")()
local noise_component = component.list("noise")()

local sound, beep, noise
if sound_component then
  sound = component.proxy(sound_component)
end
if beep_component then
  beep = component.proxy(beep_component)
end
if noise_component then
  noise = component.proxy(noise_component)
end

local snd = {}

setmetatable(snd, { __index = function(_, k) error("Attempt to index sound." .. k .. " (a nil value)") end })

snd.noise = noise
snd.beep = beep
snd.sound = sound
if snd.noise then
  snd.modes = snd.noise.modes
end

function snd.beeps(beeps)
  checkArg(1, beeps, "table")
  return snd.beep.beep(beeps)
end

function snd.noises(noises)
  checkArg(1, noises, "table")
  return snd.noise.play(noises)
end

function snd.sounds(sounds)
  checkArg(1, sounds, "table") -- each entry should be formatted as {channel, mode, frequency, duration, asdr}
  for i=1, #sounds, 1 do
    checkArg(1, sounds[1], "number")
    checkArg(2, sounds[2], "number")
    checkArg(3, sounds[3], "number")
    checkArg(4, sounds[4], "number")
    checkArg(5, sounds[5], "table")
    snd.sound.setWave(sounds[1], sounds[2])
    snd.sound.setFrequency(sounds[1], sounds[3])
    snd.sound.setASDR(sounds[1], table.unpack(sounds[5]))
    snd.sound.open(sounds[1])
    snd.sound.delay(sounds[4])
  end
end

return snd
