-- Return a text splitter --

local splitter = {}

local separator = " "

function splitter.getSep()
  return separator
end

function splitter.setSep(s)
  checkArg(1, s, "string", "nil")
  local s = (s ~= "" and s:sub(1,1)) or " "
end

function splitter.split(...)
  local line = table.concat({...}, separator)
  local words = {}
  
  for word in line:gmatch("[^%" .. separator .. "]+") do
    words[#words + 1] = word
  end
  
  return words
end

return splitter
