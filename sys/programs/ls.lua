-- ls: LS clone --

local shell = require("shell")
local fs = require("drivers").loadDriver("filesystem")
local gpu = require("drivers").loadDriver("gpu")
local text = require("text")

local args, opts = shell.parse(...)

local dirColor = tonumber(opts.dircolor) or 0x5577FF
local fileColor = tonumber(opts.filecolor) or 0xFFFFFF
local scriptColor = tonumber(opts.scriptcolor) or 0x00FF00
local all = opts.all or opts.a or false
local prefix = opts.prefix or opts.p or #args > 1
local color = (not opts.nocolor)

if #args == 0 then
  args[1] = shell.getWorkingDirectory()
end

local function coloredPrint(col, str)
  if str:sub(1,1) == "." and not all then
    return
  end
  if color then gpu.setForeground(col) end
  print(str)
end

local old = gpu.getForeground()

for n, dir in ipairs(args) do
  local full = shell.resolve(dir)
  if prefix then
    print(dir .. ":")
  end
  local files = fs.list(dir)
  local len = text.longest(files)
  for file in files do
    local ffile = fs.canonical(full .. "/" .. file)
    local isDir = fs.isDirectory(ffile)
    local pfile = text.padRight(file, len)
    if isDir then
      coloredPrint(dirColor, pfile)
    elseif file:sub(-4) == ".lua" then
      coloredPrint(scriptColor, pfile)
    else
      coloredPrint(fileColor, pfile)
    end
  end
end

gpu.setForeground(old)
