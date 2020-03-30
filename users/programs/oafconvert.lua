-- note: convert text files to OAF --

local shell = require("shell")
local fs = require("filesystem")
local sound = require("drivers").loadDriver("sound")

local base = {
  a = 27,
  b = 31,
  c = 33,
  d = 37,
  e = 41,
  f = 44,
  g = 49
}

local sharp = {
  a = 29,
  b = 33,
  c = 35,
  d = 39,
  e = 44,
  f = 46,
  g = 52
}

local data = {}

local function saveToFile(file)
  local handle = io.open(file, "w")
  for i=1, #data, 1 do
    handle:write(data[i])
  end
  handle:close()
end

local function convertNote(note)
  local name = note:sub(1,1)
  local inflection = note:sub(2,2)
  local octave = note:sub(3, 3)
  local freq
  if inflection == "#" then
    freq = sharp[name]
  else
    freq = base[name]
  end
  freq = freq * (2^tonumber(octave))
  return string.pack("H", freq)
end

local function convertLine(line)
  local r = ""
  for word in line:gmatch("[^ ]+") do
    print(word)
    r = r .. convertNote(word)
  end
  r = r .. string.char(0):rep(16 - #r)
  return r
end

local args, opts = shell.parse(...)

if #args < 1 then
  io.stderr:write("Usage: oafconvert SOURCE [DEST]\n")
  os.exit(1)
end

local src = shell.resolve(args[1])
local dest
if args[2] then
  dest = shell.resolve(args[2])
else
  dest = src .. ".oaf"
end

local handle, err = io.open(src, "r")
if not handle then
  error(err)
end

local d, err = io.open(dest, "w")
if not d then
  error(err)
end

print("Converting...")

local data = handle:read("a")
print(data)
for line in data:gmatch("[^\n]+") do
  print(line)
  d:write(convertLine(line))
end

d:close()
handle:close()

print("Done.")
