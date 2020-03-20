-- io: file I/O --

local fs = require("drivers").loadDriver("filesystem")
local computer = require("computer")
local term = require("term")

local timeout = 5 -- The amount of time, in seconds, that a read operation is allowed to take.

local stdio = {
  read = function(a)
    checkArg(1, a, "number")
    local a = (a <= 2048 and a) or 2048
    local read = term.read():sub(1, a)
    return read or nil
  end,
  write = function(v)
    checkArg(1, v, "string")
    term.write(v)
  end,
  seek = function()
    return 1
  end,
  close = function()
    handle = nil
  end
}

local function create(mode, handle)
  checkArg(1, mode, "string")
  checkArg(2, handle, "userdata", "nil", "string", "table")
  if type(handle) == "string" then
    if handle == "-" then
      handle = stdio
    else
      return false, "Invalid file " .. handle
    end
  end
  handle = handle or stdio
  
  local file = {
    stream = handle,
    mode = {},
    tty = false
  }
  
  for m in mode:gmatch(".") do
    file.mode[m] = true
  end

  if file.mode.t or handle == stdio then
    file.tty = true
  end
  
  -- TODO: Possibly implement buffering
  function file:read(a)
    checkArg(1, a, "string", "number", "nil")
    if not self.mode.r then
      return nil, "Read mode was not enabled on this stream"
    end
    local a = a or "l"
    if a == "*a" or a == "a" then
      local d = ""
      local start = computer.uptime()
      repeat
        local c = self.stream.read(math.huge)
        if computer.uptime() - start >= start + timeout then -- We've exceeded the timeout!
          error("Timeout exceeded")
        end
        d = d .. (c or "")
      until not c
      return d
    elseif a == "*l" or a == "l" or a == "L" or not a then
      local l = ""
      repeat
        if self.tty then
          return self.stream.read(math.huge) .. ((a == "L" and "\n") or "")
        end
        local c = self.stream.read(1)
        l = l .. (((a ~= "L" and c ~= "\n") and c) or "")
        if c == "\n" or not c then
          return l
        end
      until not c
    elseif type(a) == "number" then
      return self.stream.read(a)
    end
  end
  
  function file:lines()
    local lines = {}
    repeat
      local line = file:read("l")
      if line then
        table.insert(lines, line)
      end
    until not line
    local i = 0
    local n = #lines
    setmetatable(lines, {
      __call = function()
        i = i + 1
        if i <= n then
          return lines[i]
        end
      end
    })
  end
  
  function file:write(val)
    checkArg(1, val, "string")
    if not self.mode.w then
      return nil, "Write mode was not enabled on this stream"
    end
    return self.stream.write(val)
  end
  
  function file:flush() -- compatibility
    return true
  end
  
  function file:setvbuf() -- compatibility
    return true
  end
  
  function file:seek(whence, offset)
    checkArg(1, whence, "string")
    checkArg(2, offset, "string")
    return handle.seek(whence, offset)
  end
  
  function file:close()
    return self.stream.close()
  end

  return file
end

_G.io = {}

io.stdin = create("r")
io.stdout = create("w")
io.stderr = create("w")

function io.output(file)
  checkArg(1, file, "string", "table", "userdata", "nil")
  if type(file) == "string" then
    local handle, err = fs.open(file, "w")
    if not handle then
      return nil, err
    end
    
    io.stdout = create("w", handle)
  elseif type(file) == "userdata" then
    io.stdout = create("w", file)
  elseif type(file) == "table" then
    if file.write and file.close then
      io.stdout = file
    else
      return nil, "Invalid file"
    end
  elseif not file then
    return io.stdout
  else
    return nil, "Invalid file"
  end
end

function io.input(file)
  checkArg(1, file, "string", "table", "userdata", "nil")
  if type(file) == "string" then
    local handle, err = fs.open(file, "r")
    if not handle then
      return nil, err
    end
    
    io.stdin = create("r", handle)
  elseif type(file) == "userdata" then
    io.stdin = create(file)
  elseif type(file) == "table" then
    if file.read and file.readLine and file.lines and file.close then
      io.stdin = file
    else
      return nil, "Invalid file"
    end
  elseif not file then
    return io.stdin
  else
    return nil, "Invalid file"
  end
end

function io.open(file, mode)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  local mode = mode or "r"
  
  if file == "-" then
    return create(mode)
  end

  local handle, err = fs.open(file, mode)
  if not handle then
    return nil, err
  end
  
  return create(mode, handle)
end

function io.write(d)
  return io.output():write(d)
end

function io.read(a)
  return io.input():read(a)
end

function io.lines()
  return io.input():lines()
end

function io.flush()
  io.output():flush()
end

function io.close(file)
  checkArg(1, file, "table")
  if file.close then
    return file:close()
  end
  return io.output():close()
end

function io.type(obj)
  if type(obj) == "table" and ((obj.read and obj.readLine and obj.lines) or obj.write) then
    if obj.closed then
      return "closed file"
    else
      return "file"
    end
  end
  return nil
end
