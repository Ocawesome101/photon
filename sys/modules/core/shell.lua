-- The shell API --

local shell = {}
local fs = require("drivers").loadDriver("filesystem")
local sched = require("sched")
local splitter = require("splitter")
local computer = require("computer")
local errHandler = error

local escapes = {
  ["w"] = function()
    return os.getenv("PWD")
  end,
  ["u"] = function()
    return os.getenv("USER")
  end,
  ["$"] = function()
    return "#"
  end,
  ["h"] = function()
    return os.getenv("HOSTNAME") or "photon::" .. os.build()
  end
}

fs.makeDirectory("/users/home")
os.setenv("PWD", "/users/home")
os.setenv("PATH", "/sys/programs:/users/programs")
os.setenv("PS1", "\\u@\\h: \\w\\$ ")
os.setenv("HOME", "/users/home")

function shell.resolve(path)
  checkArg(1, path, "string")
  if path:sub(1,1) == "/" then
    return fs.canonical(path)
  else
    return fs.canonical(os.getenv("PWD") .. "/" .. path)
  end
end

function shell.getWorkingDirectory()
  return os.getenv("PWD")
end

function shell.setWorkingDirectory(value)
  local path = shell.resolve(value)
  if fs.exists(path) then
    if fs.isDirectory(path) then
      return os.setenv("PWD", path)
    else
      return nil, "File is not a directory"
    end
  else
    return nil, "No such file or directory"
  end
end

function shell.getPath()
  return os.getenv("PATH")
end

function shell.setPath(value)
  checkArg(1, value, "string")
  for path in value:gmatch("[^:]+") do
    if not fs.exists(path) then
      return nil, "path " .. path .. " does not exist"
    end
  end
  os.setenv("PATH", value)
end

function shell.getErrorHandler()
  return errHandler
end

function shell.setErrorHandler(func)
  checkArg(1, func, "function")
  errHandler = func
end

function shell.execute(cmd, ...)
  checkArg(1, cmd, "string")
  
  if cmd:sub(-1) == "\n" then
    cmd = cmd:sub(1, -2)
  end
  
  local tokens = splitter.split(cmd, ...)
  cmd = tokens[1]
  table.remove(tokens, 1)
  local search = os.getenv("PATH") or os.getenv("PWD")
  local absolute = ""
  for path in search:gmatch("[^%:]+") do
    local p = fs.canonical(path .. "/" .. cmd)
    if fs.exists(p) then
      absolute = p
      break
    elseif fs.exists(p .. ".lua") then
      absolute = p .. ".lua"
      break
    end
  end
  
  if not fs.exists(absolute) or absolute == "" then
    error(cmd .. ": Command not found")
  end

  if tokens[1] then
    os.setenv("_", tokens[1])
  end
  
  local ok, err = loadfile(absolute)
  if not ok and err then
    error(err)
  end
  
  --return ok(table.unpack(tokens))
  local pid = sched.spawn(function()return ok(table.unpack(tokens))end, absolute, errHandler)
  repeat
    local running = false
    for _, p in pairs(sched.processes()) do
      if p == pid then
        running = true
      end
    end
    local from, evt, status = computer.pullSignal()
  until not running
end

function shell.parse(...)
  local arguments = table.concat({...}, " ")
  local rargs, ropts = {}, {}
  local current = ""
  for word in arguments:gmatch("[^ ]+") do
    if word:sub(1, 1) == "-" then
      if word:sub(1, 2) == "--" then
        local opt = ""
        local optarg = true
        for char in word:sub(3):gmatch(".") do
          if type(optarg) ~= "string" then
            if char == "=" then
              optarg = ""
            else
              opt = opt .. char
            end
          else
            optarg = optarg .. char
          end
        end
        ropts[opt] = optarg
      else
        for char in word:sub(2):gmatch(".") do
          ropts[char] = true
        end
      end
    else
      rargs[#rargs + 1] = word
    end
  end
  return rargs, ropts
end

function shell.prompt(str)
  local rtn = ""
  local inEsc = false
  local last = ""
  local esc = ""
  for char in str:gmatch(".") do
    if char == "\\" and last ~= "\\" then
      inEsc = true
    elseif inEsc then
      rtn = rtn .. (escapes[char] and escapes[char]()) or char
      inEsc = false
    else
      rtn = rtn .. char
      last = char
    end
  end
  return rtn
end

return shell
