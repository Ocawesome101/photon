-- rm: delete files --

local shell = require("shell")
local fs = require("drivers").loadDriver("filesystem")
local prompts = require("utils/prompts")

local args, opts = shell.parse(...)

local recurse = opts.r or false
local interactive = opts.i or opts.interactive or false
local verbose = opts.v or opts.verbose or false

if #args < 1 then
  error("usage: rm FILE1 FILE2 ...", 0)
end

local function r(f)
  if verbose then print(string.format("removing %s", f)) end
end

for i=1, #args, 1 do
  local file = shell.resolve(args[i])
  if not fs.exists(file) then
    error(args[i] .. ": file not found")
  end
  if interactive then
    local rm = prompts.yesno("remove " .. args[i] .. "?", "y")
    if rm then
      r(file)
      fs.remove(file)
    else
      print("skipping " .. args[i])
    end
  else
    r(file)
    fs.remove(file)
  end
end
