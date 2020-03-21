-- filesystem label manager --

local shell = require("shell")
local fs = require("drivers").loadDriver("filesystem")

local args, options = shell.parse(...)

if #args < 2 then
  print("usage: label set PATH WORD1 WORD2 ...")
  print("   or: label get PATH")
  print("   or: label clear PATH")
  return
end

local op = args[1]
local path = shell.resolve(args[2])
local label = args[3] and table.concat({table.unpack(args, 3, #args)}, " ")

if op == "get" then
  return print("Label of " .. path .. " is \"" .. fs.getLabel(path) .. "\"")
elseif op == "set" then
  return print("Label set to \"" .. (fs.setLabel(label, path) or label:sub(1, 32)) .. "\"")
elseif op == "clear" then
  return print("Label cleared"), fs.setLabel("", path)
else
  return print("label: Unrecognized argument " .. op)
end
