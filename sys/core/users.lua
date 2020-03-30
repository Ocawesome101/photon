-- user system --

local config = require("config")
local sha3 = require("sha3")
local term = require("term")

local user = "guest"
local uid = 0

local cfg = config.loadWithDefaults("/sys/config/users.cfg", {
  {
    name = "root",
    uid = 0,
    password = sha3.sha256("root")
  }
})

local users = {}

function users.login(u)
  checkArg(1, u, "string")
  local times = 3
  repeat
    local pwd = sha3.sha256(term.read(nil, "*"))
    for i=1, #cfg, 1 do
      if cfg[i].name == u and cfg[i].password == pwd then
        user = u
        uid = cfg[i].uid
        os.setenv("USER", u)
        os.setenv("UID", uid)
        return true
      end
    end
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
