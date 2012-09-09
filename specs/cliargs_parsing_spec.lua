require("busted")

-- some helper stuff for debugging
local quoted = function(s)
  return "'" .. tostring(s) .. "'" 
end
local dump = function(t)
  print(" ============= Dump " .. tostring(t) .. " =============")
  if type(t) ~= "table" then
    print(quoted(tostring(t)))
  else
    for k,v in pairs(t) do
      print(quoted(k),quoted(v))
    end
  end
  print(" ============= Dump " .. tostring(t) .. " =============")
end

local cli
-- start tests
describe("Testing cliargs library parsing commandlines", function()

  setup(function()
    _TEST = true
    package.loaded.cliargs = false  -- Busted uses it, but must force to reload 
    cli = require("cliargs")
  end)

  teardown(function()
    _TEST = false
  end)
  
end)