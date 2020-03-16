-- The base of the Modularity desktop environment. --

print("Modularity: loading configuration")

local config = require("config")

local cfg = config.loadWithDefault("/sys/config/modularity.cfg", {
  buffer = {
    "hardware",
    "software",
    "none"
  }
})
