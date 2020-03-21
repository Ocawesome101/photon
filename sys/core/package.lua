-- package library --

local fs = drivers.loadDriver("filesystem")

_G.package = {}

package.path = "/sys/modules/?.lua;/sys/modules/?/init.lua;/sys/modules/core/?.lua;/sys/modules/core/?/init.lua;/users/shared/?.lua;/users/shared/?/init.lua"

package.loaded = {
  ["_G"] = _G,
  ["table"] = table,
  ["string"] = string,
  ["math"] = math,
  ["bit32"] = bit32,
  ["computer"] = computer,
  ["unicode"] = unicode,
  ["coroutine"] = coroutine,
  ["sched"] = sched,
  ["drivers"] = drivers,
  ["signals"] = sched.signals
}

_G.component, _G.computer, _G.unicode, _G.drivers, _G.sched = nil, nil, nil, nil, nil

local function genLibError(p, n)
  local err = "module '%s' not found:\n\tNo field package.preload['%s']\n"
  local paths = {}
  for path in p:gmatch("[^;]+") do
    err = err .. "\tNo file '%s'\n"
    paths[#paths + 1] = path:gsub("%?", n)
  end
  return err:format(n, n, table.unpack(paths))
end

function package.searchpath(name, path, sep, rep)
  checkArg(1, name, "string")
  checkArg(2, path, "string")
  checkArg(3, sep, "string", "nil")
  checkArg(4, rep, "string", "nil")
  local sep = sep or "."
  local rep = rep or "/"
  local name = name:gsub("%"..sep, "%"..rep)
  for path in path:gmatch("[^;]+") do
    path = path:gsub("%?", name)
    if fs.exists(path) then
      return path
    end
  end
  return false, genLibError(path, name)
end

function _G.dofile(file)
  local ok, err = loadfile(file)
  if not ok then
    return nil, err
  end
  local s, r = pcall(ok)
  if s then
    return r
  else
    return nil, r
  end
end

function _G.require(modname)
  if package.loaded[modname] then
    return package.loaded[modname]
  else
    local path, err = package.searchpath(modname, package.path, ".", "/")
    if not path then
      return nil, err
    end
    local ok, err = dofile(path)
    if not ok then
      error(err)
    end
    package.loaded[modname] = ok
    return ok
  end
end
