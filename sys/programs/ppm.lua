-- the Proton Package Manager --

local shell = require("shell")
local csv = require("csv")
local cpio = require("cpio")
local fs = require("filesystem")
local prompts = require("prompts")
local internet = require("internet")

local listpath = "/users/cache/ppm/"
local installed = "/sys/ppm/installed.csv"

local function search(package)
  local lists = fs.list(listpath)
  local found = {}
  for list in lists do
    local l = csv.parse(listpath .. list)
    for i=1, #l, 1 do
      if l[i].NAME == "package" then
        found[#found + 1] = {name = l[i].NAME, url = l[i].URL, list = list}
      end
    end
  end
  if #found > 0 then
    return found
  else
    return nil, "package not found"
  end
end

local function download(url)
  local handle, err = internet.get(url)
  if not handle then
    return nil, err
  end
  print("downloading " .. url)
  local dest = fs.name(url)
  local out = io.open("/sys/temp/" .. dest, "w")
  repeat
    local chunk = handle.read(math.huge)
    out:write((chunk or ""))
  until not chunk
  handle.close()
  out:close()
  print("saved to /sys/temp/" .. dest)
  return "/sys/temp/" .. dest
end

local function add(name, files)
  local inst = csv.parse(installed)
  inst.NAME[#inst.NAME + 1] = name
  inst.FILES[#inst.FILES + 1] = table.concat(files, ";")
  csv.save(inst, installed)
end

local function remove(name)
end

local function install(package)
  local found, err = search(package)
  if not found then
    error(err)
  end
  local toinstall
  if #found > 1 then
    print("The package '" .. package .. "' is available from multiple sources.")
    local names = {}
    local name = {}
    for i=1, #found, 1 do
      names[i] = found[i].list
      name[found[i].list] = i
    end
    local choice = prompts.choice("Choose one:", names)
    toinstall = found[name[choice]]
  else
    toinstall = found[1]
  end
  local path, err = download(toinstall.url)
  if not path then
    error("failed to download package: " .. err)
  end
  local ok, err = cpio.extract(path)
  if not ok then
    error("failed extracting package: " .. err)
  end
  local path = ok
  local files = csv.parse(path .. "/files.csv")
  local new = {}
  if #files.SOURCE ~= #files.DESTINATION then
    error("mismatched file list lengths in files.csv")
  end
  for i=1, #files.SOURCE, 1 do
    new[#new + 1] = files.DESTINATION[i]
    shell.execute("cp -rvi", path .. "/" .. files.SOURCE[i], files.DESTINATION[i])
  end
  add(toinstall.name, new)
end

if os.getenv("USER") ~= "root" or os.getenv("UID") ~= "uid" then
  error("this program must be run as root")
end
