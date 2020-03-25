-- Filesystem drivers. Pretty much copied from Open Kernel 2 :P --

local fs = {}

local component = ...
local boot_address = computer.getBootAddress()

local mounts = {
  {
    path = "/",
    proxy = component.proxy(boot_address)
  }
}

local function split(s, ...)
  checkArg(1, s, "string")
  local rw = {}
  local _s = table.concat({...}, s)
  for w in _s:gmatch("[^%" .. s .. "]+") do
    rw[#rw + 1] = w
  end
  local i=1
  setmetatable(rw, {__call = function()
    i = i + 1
    if rw[i - 1] then
      return rw[i - 1]
    else
      return nil
    end
  end
  })
  return rw
end

local function cleanPath(p)
  checkArg(1, p, "string")
  local path = ""
  for segment in p:gmatch("[^%/]+") do
    path = path .. "/" .. (segment or "")
  end
  if path == "" then
    path = "/"
  end
  return path
end

fs.clean = cleanPath

local function resolve(path) -- Resolve a path to a filesystem proxy
  checkArg(1, path, "string")
  local proxy
  local path = cleanPath(path)
  for i=1, #mounts, 1 do
    if mounts[i] and mounts[i].path then
      local pathSeg = cleanPath(path:sub(1, #mounts[i].path))
      if pathSeg == mounts[i].path then
        path = cleanPath(path:sub(#mounts[i].path + 1))
        proxy = mounts[i].proxy
      end
    end
  end
  if proxy then
     return cleanPath(path), proxy
  end
end

function fs.mount(addr, path)
  checkArg(1, addr, "string")
  checkArg(2, path, "string", "nil")
  local label = component.invoke(addr, "getLabel")
  label = (label ~= "" and label) or nil
  local path = path or "/mount/" .. (label or addr:sub(1, 6))
  path = cleanPath(path)
  local p, pr = resolve(path)
  for _, data in pairs(mounts) do
    if data.path == path then
      if data.proxy.address == addr then
        return true, "Filesystem already mounted"
      else
        return false, "Cannot override existing mounts"
      end
    end
  end
  if component.type(addr) == "filesystem" then
    if fs.makeDirectory then
      fs.makeDirectory(path)
    end
    mounts[#mounts + 1] = {path = path, proxy = component.proxy(addr)}
    return true
  end
  return false, "Unable to mount"
end

function fs.umount(path)
  checkArg(1, path, "string")
  for k, v in pairs(mounts) do
    if v.path == path then
      mounts[k] = nil
      fs.remove(v.path)
      return true
    elseif v.proxy.address == path then
      mounts[k] = nil
      fs.remove(v.path)
    end
  end
  return false, "No such mount"
end

function fs.mounts()
  local rtn = {}
  for k,v in pairs(mounts) do
    rtn[k] = {path = v.path, address = v.proxy.address, label = v.proxy.getLabel()}
  end
  return rtn
end

function fs.exists(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(cleanPath(path))
  if not proxy.exists(path) then
    return false
  else
    return true
  end
end

function fs.open(file, mode)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  if not fs.exists(file) and mode ~= "w"  then
    return false, "No such file or directory"
  end
  local mode = mode or "r"
  if mode ~= "r" and mode ~= "rw" and mode ~= "w" then
    return false, "Unsupported mode"
  end
  local path, proxy = resolve(file)
  local h, err = proxy.open(path, mode)
  if not h then
    return false, err
  end
  local handle = {}
  if mode == "r" or mode == "rw" or not mode then
    handle.read = function(n)
      return proxy.read(h, n)
    end
  end
  if mode == "w" or mode == "rw" then
    handle.write = function(d)
      return proxy.write(h, d)
    end
  end
  handle.close = function()
    proxy.close(h)
  end
  handle.seek = function(w, o)
    return proxy.seek(w, o)
  end
  handle.handle = function()
    return h
  end
  return handle
end

function fs.list(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  local files = proxy.list(path)
  local i = 1
  local mt = {
    __call = function()
      i = i + 1
      if files[i - 1] then
        return files[i - 1]
      else
        return nil
      end
    end
  }
  return setmetatable(files, mt)
end

function fs.remove(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  return proxy.remove(path)
end

function fs.spaceUsed(path)
  checkArg(1, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.spaceUsed()
end

function fs.makeDirectory(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  return proxy.makeDirectory(path)
end

function fs.isReadOnly(path)
  checkArg(1, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.isReadOnly()
end

function fs.spaceTotal(path)
  checkArg(1, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.spaceTotal()
end

function fs.isDirectory(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  return proxy.isDirectory(path)
end

function fs.copy(source, dest)
  checkArg(1, source, "string")
  checkArg(2, dest, "string")
  local spath, sproxy = resolve(source)
  local dpath, dproxy = resolve(dest)

  local s, err = sproxy.open(spath, "r")
  if not s then
    return false, err
  end
  local d, err = dproxy.open(dpath, "w")
  if not d then
    sproxy.close(s)
    return false, err
  end
  repeat
    local data = sproxy.read(s, 0xFFFF)
    dproxy.write(d, (data or ""))
  until not data
  sproxy.close(s)
  dproxy.close(d)
  return true
end

function fs.rename(source, dest)
  checkArg(1, source, "string")
  checkArg(2, dest, "string")

  local ok, err = fs.copy(source, dest)
  if ok then
    fs.remove(source)
  else
    return false, err
  end
end

function fs.canonical(path)
  checkArg(1, path, "string")
  local segments = split("/", path)
  for i=1, #segments, 1 do
    if segments[i] == ".." then
      segments[i] = ""
      table.remove(segments, i - 1)
    end
  end
  return cleanPath(table.concat(segments, "/"))
end

function fs.path(path)
  checkArg(1, path, "string")
  local segments = split("/", path)
  
  return cleanPath(table.concat({table.unpack(segments, 1, #segments - 1)}, "/"))
end

function fs.name(path)
  checkArg(1, path, "string")
  local segments = split("/", path)

  return segments[#segments]
end

function fs.get(path)
  checkArg(1, path, "string")
  if not fs.exists(path) then
    return false, "Path does not exist"
  end
  local path, proxy = resolve(path)

  return proxy
end

function fs.lastModified(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  return proxy.lastModified(path)
end

function fs.getLabel(path)
  checkArg(1, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.getLabel()
end

function fs.setLabel(label, path)
  checkArg(1, label, "string")
  checkArg(2, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.setLabel(label)
end

function fs.size(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  return proxy.size(path)
end

fs.makeDirectory("/mount")

for addr, _ in component.list("filesystem") do
  if addr ~= boot_address then
    if component.invoke(addr, "getLabel") == "tmpfs" then
      fs.mount(addr, "/sys/temp")
    elseif component.invoke(addr, "exists", ".photonmount") then -- .photonmount can specify a mount path
      local h = component.invoke(addr, "open", ".photonmount")
      local d = component.invoke(addr, "read", math.huge)
      component.invoke(addr, "close", handle)
      fs.mount(addr, d)
    else
      fs.mount(addr)
    end
  end
end

return fs
