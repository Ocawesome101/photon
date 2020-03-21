-- wc. Note that on low-memory systems you may OOM, as wc loads the entire file into memory. --

local shell = require("shell")
local text = require("text")

local args, opts = shell.parse(...)

local words = opts.w or false
local lines = opts.l or false
local chars = opts.c or false

if not words and not chars and not lines then
  words, lines, chars = true, true, true
end

if #args == 0 then
  error("Usage: wc [-wlc] FILE")
end

local handle, err = io.open(shell.resolve(args[1]), "r")
if not handle then error(err) end

local data = handle:read("a")
handle:close()

local w, l, c = 0, 0, 0

if words then
  for word in data:gmatch("[^ ]+") do
    w = w + 1
  end
  io.write(text.padRight(tostring(w), 6))
end

if lines then
  for line in data:gmatch("[^\n]+") do
    l = l + 1
  end
  io.write(text.padRight(tostring(l), 6))
end

if chars then
  for char in data:gmatch(".") do
    c = c + 1
  end
  io.write(text.padRight(tostring(c), 6))
end

io.write("\n")
