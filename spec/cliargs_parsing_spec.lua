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
  
  it("tests no arguments set, nor provided", function()
    arg = nil
    result = cli:parse()
    assert.are.same(result, {})
  end)
  
  pending("tests only optionals, nothing provided", function()
  end)
  
  pending("tests only required, all provided", function()
  end)
  
  pending("tests only optionals, all provided", function()
  end)
  
  pending("tests optionals + required, all provided", function()
  end)
  
  pending("tests optionals + required, no optionals and to little required provided, ", function()
  end)

  pending("tests optionals + required, no optionals and to many required provided, ", function()
  end)
  
end)