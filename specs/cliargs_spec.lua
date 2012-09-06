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

-- start tests
describe("Testing cliargs library", function()

  local cli
  
  setup(function()
    _TEST = true
    package.loaded.cliargs = false  -- Busted uses it, but must force to reload to test it with _TEST
    cli = require("cliargs")
  end)

  teardown(function()
  end)

  before_each(function()
    cli = cli:new()
  end)

  after_each(function()
  end)

  describe("testing private functions", function()

    it("tests the private expand() function", function()
      -- takes: str, size, fill
      assert.are.equal(cli.expand("Hello", 10) .. "x", "Hello     x")
      assert.are.equal(cli.expand("Hello", 10, "="), "Hello=====")
      assert.are.equal(cli.expand("Hello", 3), "Hello")
    end)

    it("tests the private split() function", function()
      -- takes: str, split-char
      local expected, result
      
      result = cli.split("hello,world",",")
      expected = {"hello", "world"}
      assert.is.same(result, expected)

      result = cli.split("hello,world,",",")
      expected = {"hello", "world"}
      assert.is.same(result, expected)

      result = cli.split("hello",",")
      expected = {"hello"}
      assert.is.same(result, expected)

      result = cli.split("",",")
      expected = {}
      assert.is.same(result, expected)

    end)

--[[  Join() has been removed from the code
    it("tests the private join() function", function()
      -- takes: table, separator
      local expected, result
      
      result = cli.join( {"hello", "there", "world" },",")
      expected = "hello,there,world"
      assert.is.same(result, expected)

      result = cli.join({"hello","world",""},",")
      expected = "hello,world,"
      assert.is.same(result, expected)

      result = cli.join({"hello","","world"}, ",")
      expected = "hello,,world"
      assert.is.same(result, expected)

    end)
--]]

    it("tests the private trim() function", function()
      -- test from Lua wiki
      assert.is.same(cli.trim(''),'')
      assert.is.same(cli.trim(' '),'')
      assert.is.same(cli.trim('  '),'')
      assert.is.same(cli.trim('a'),'a')
      assert.is.same(cli.trim(' a'),'a')
      assert.is.same(cli.trim('a '),'a')
      assert.is.same(cli.trim(' a '),'a')
      assert.is.same(cli.trim('  a  '),'a')
      assert.is.same(cli.trim('  ab cd  '),'ab cd')
      assert.is.same(cli.trim(' \t\r\n\f\va\000b \r\t\n\f\v'),'a\000b')
    end)

    it("tests the private delimit() function", function()
      -- takes: text, size, padding
      local text = "123456789 123456789 123456789!"
      local expected, result
      
      result = cli.delimit(text, 10)
      expected = "123456789\n123456789\n123456789!"
      assert.is.same(result, expected)

      -- exact length + 1 overflow
      result = cli.delimit(text, 9)
      expected = "123456789\n123456789\n123456789\n!"
      assert.is.same(result, expected)

      result = cli.delimit(text, 9, nil, true)
      expected = "123456789\n123456789\n123456789!"
      assert.is.same(result, expected)

      result = cli.delimit(text, 8)
      expected = "12345678\n9\n12345678\n9\n12345678\n9!"
      assert.is.same(result, expected)
    end)

  end)   -- private functions
  
  
end)