-- cp: cp clone --

local shell = require("shell")
local term = require("term")
local fs = require("drivers").loadDriver("filesystem")
local prompts = require("utils/prompts")

local args, opts = shell.parse(...)

local recurse = opts.r or false
local verbose = opts.v or opts.verbose or false
local prompt = opts.i or opts.interactive or not (opts.n or opts.noclobber)

if #args < 2 then
  error("usage: cp [-rvi] FILE DEST", 0)
end

local function copy(file, dest)
  if fs.exists(dest) then
    if prompt then
      local yn = prompts.yesno("overwrite " .. dest .. "?", "y")
      if not yn then
        return
      end
    else
      print("not overwriting " .. dest .. ": already exists")
      return
    end
  end
  if verbose then
    print(string.format("%s -> %s", file, dest))
  end
  if fs.isDirectory(file) then
    fs.makeDirectory(dest)
    for o in fs.list(file) do
      copy(file .. "/" .. o, dest .. "/" .. o)
    end
  else
    fs.copy(file, dest)
  end
end

local source = shell.resolve(args[1])
local destination = shell.resolve(args[2])

if fs.isDirectory(source) then
  if recurse then
    copy(source, destination)
  else
    error("-r not specified; not copying " .. args[1], 0)
  end
end

copy(source, destination)
