-- Set up userspace --

local logger = ...

logger.prefix = "Proton Userspace:"
local drivers = require("drivers")
local fs = drivers.loadDriver("filesystem")
local component = require("component")
local sched = require("sched")
local uscfg = {
  allow_component = false,
  shell = "/sys/programs/shell.lua"
}

logger.log("Reading userspace configuration")
local ok, err = loadfile("/sys/userspace.cfg", "t", {}, "return ")
if ok then
  local s, r = pcall(ok)
  if s then
    uscfg = r
  end
end

if not uscfg.allow_component then
  logger.log("Disallowing component")
  package.loaded["component"] = nil -- Disallow access to this except in drivers
end

local userspace = {
  _OSVERSION = string.format("%s build %s", os.uname(), os.build()),
  assert = assert,
  error = error,
  getmetatable = getmetatable,
  ipairs = ipairs,
  load = load,
  next = next,
  pairs = pairs,
  pcall = pcall,
  rawequal = rawequal,
  rawget = rawget,
  rawlen = rawlen,
  rawset = rawset,
  select = select,
  setmetatable = setmetatable,
  tonumber = tonumber,
  tostring = tostring,
  type = type,
  xpcall = xpcall,
  require = require,
  dofile = dofile,
  checkArg = checkArg,
  bit32 = setmetatable({}, {__index=bit32}),
  debug = setmetatable({}, {__index=debug}),
  math = setmetatable({}, {__index=math}),
  os = setmetatable({}, {__index=os}),
  string = setmetatable({}, {__index=string}),
  table = setmetatable({}, {__index=table}),
  package = setmetatable({}, {__index=package}),
  io = setmetatable({}, {__index=io}),
  coroutine = {
    yield = coroutine.yield
  },
  ["_G"] = userspace
}

local term = require("term")

function userspace.print(...)
  local args = {...}
  for i=1, #args, 1 do
    term.write(args[i])
    if i < #args then
      term.write(" ")
    end
  end
  term.write("\n")
end

function userspace.loadfile(file, mode, env)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  checkArg(3, env, "table", "nil")
  local mode = mode or "bt"
  local env = env or userspace
  
  local handle, err = io.open(file, "r")
  if not handle then
    return nil, err
  end
  local data = handle:read("a")
  handle:close()
  
  return load(data, "=" .. file, mode, env)
end

function package.loaded.computer.pullSignal()
  return coroutine.yield()
end

logger.log("Starting shell")
local ok, err = loadfile(uscfg.shell or "/sys/programs/shell.lua", "t", userspace)
if not ok then
  logger.prefix = "SHELL ERROR:"
  logger.log(err)
  require("computer").beep(400, 1)
  while true do
    require("computer").pullSignal()
  end
end

--while true do logger.log(coroutine.yield()) end

local function userspaceError(err, lvl)
  local trace = debug.traceback(err, lvl)
  term.write("ERROR IN THREAD " .. sched.current() .. "\n")
  term.write(trace)
  sched.kill(sched.current())
end

sched.spawn(ok, "shell", userspaceError)
