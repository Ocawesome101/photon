-- Set up the userspace sandbox

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
  checkArg = checkArg,
  bit32 = setmetatable({}, {__index=bit32}),
  debug = setmetatable({}, {__index=debug}),
  math = setmetatable({}, {__index=math}),
  os = setmetatable({}, {__index=os}),
  string = setmetatable({}, {__index=string}),
  table = setmetatable({}, {__index=table}),
  drivers = setmetatable({}, {__index=drivers}),
  sched = setmetatable({}, {__index=sched}),
  computer = setmetatable({}, {__index=computer}),
  unicode = setmetatable({}, {__index=unicode}),
  component = setmetatable({}, {__index=component}),
  coroutine = {
    yield = coroutine.yield
  }
}

userspace._G = userspace
