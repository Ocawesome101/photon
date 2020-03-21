-- mount: get fs mounts / mount filesystems --

local shell = require("shell")
local text = require("text")
local component_get = require("drivers").loadDriver("component/get")
local fs = require("drivers").loadDriver("filesystem")

local args, options = shell.parse(...)

local usage = [[mount (c) 2020 Ocawesome101 under the MIT license.
usage: mount addr /path
   or: mount -h, --help
]]

if #args < 1 then
  local mts = fs.mounts()
  local longestPath = 0
  local longestLabel = 0
  for k,v in pairs(mts) do
    if #v.path > longestPath then
      longestPath = #v.path
    end
    if v.label and #v.label > longestLabel then
      longestLabel = #v.label
    end
  end
  for k,v in pairs(mts) do
    print(text.padRight(v.address:sub(1, 8) .. " on " .. v.path, longestLabel + longestPath + 6) .. (fs.get(v.path).isReadOnly() and " (ro)" or " (rw)") .. (" \"" .. (v.label or v.address) .. "\""))
  end
  return
end

local addr = args[1]
local mtpath = (args[2] and shell.resolve(args[2])) or "/mount/"
local fullAddr = component_get(addr)

if not fullAddr then
  return print("mount: " .. mtpath .. ": component " .. addr .. " does not exist")
end

if not fs.exists(mtpath) then
  fs.makeDirectory(mtpath)
end

local ok, err = fs.mount(fullAddr, mtpath)
if not ok then
  print("mount: " .. err)
end
