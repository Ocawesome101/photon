-- user system --

local config = require("config")
local sha3 = require("sha3")
local term = require("term")

local user = "user"
local uid = 1

local cfg = config.loadWithDefaults("/sys/config/users.cfg", {
  {
    name = "root",
    uid = 0,
    password = sha3.sha256("root")
  }
})

local users = {}

function users.sudo(...)
  local u = "root"
  local times = 3
  local args = {...}
  repeat
    io.write("root password: ")
    local pwd = term.read(nil, "*"):sub(1, -2)
    pwd = sha3.sha256(pwd)
    io.write("\n")
    for i=1, #cfg, 1 do
      if cfg[i].name == u and cfg[i].password == pwd then
        local olduser = user
        local olduid = uid
        user = u
        uid = cfg[i].uid
        os.setenv("USER", u)
        os.setenv("UID", uid)
        local s, r = pcall(function()return require("shell").execute(table.unpack(args))end)
        user = olduser
        uid = olduid
        os.setenv("USER", user)
        os.setenv("UID", uid)
        return s, r
      end
    end
    io.stderr:write("invalid credentials\n")
  until times == 0
  return nil, "incorrect credentials"
end

function users.user()
  return user
end

function users.uid()
  return uid
end

os.setenv("USER", user)
os.setenv("UID", uid)

package.loaded.users = users
