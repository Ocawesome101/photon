-- text: OpenOS-compatible text API --

local splitter = require("utils/splitter")

local text = {}

function text.longest(tbl)
  checkArg(1, tbl, "table")
  local len = 0
  for i=1, #tbl, 1 do
    if type(tbl[i]) == "string" and #tbl[i] > len then
      len = #tbl[i]
    end
  end
  return len
end

function text.tokenize(str)
  checkArg(1, str, "string")
  splitter.setSep(" ")
  return splitter.split(str)
end

function text.padRight(str, len)
  checkArg(1, str, "string")
  checkArg(2, len, "number")
  local diff = len - #str
  return str .. (" "):rep(diff)
end

function text.padLeft(str, len)
  checkArg(1, str, "string")
  checkArg(2, len, "number")
  local diff = len - #str
  return (" "):rep(diff) .. str
end

function text.detab(str, tabWidth)
  checkArg(1, str, "string")
  checkArg(2, tabWidth, "number", "nil")
  local tabWidth = tabWidth or 4
  return str:gsub("\t", (" "):rep(tabWidth))
end

return text
