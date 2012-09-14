-- require("busted")

-- some helper stuff for debugging
local quoted = function(s)
  return "'" .. tostring(s) .. "'" 
end
local dump = function(t)
  print(" ============= Dump " .. tostring(t) .. " =============")
  if type(t) ~= "table" then
    if type(t) == "string" then
      print(quoted(tostring(t)))
    else
      print(tostring(t))
    end
  else
    for k,v in pairs(t) do
      if type(v) == "string" then
        print(quoted(k),quoted(v))
      else
        print(quoted(k),tostring(v))
      end
    end
  end
  print(" ============= Dump " .. tostring(t) .. " =============")
end

local cli
-- start tests
describe("Testing cliargs library methods/functions", function()

  describe("testing private functions", function()

    setup(function()
      _TEST = true
      package.loaded.cliargs = false  -- Busted uses it, but must force to reload to test it with _TEST
      cli = require("cliargs")
    end)

    teardown(function()
      _TEST = nil
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

    it("tests the private wordwrap() function", function()
      -- takes: text, size, padding
      local text = "123456789 123456789 123456789!"
      local expected, result
      
      result = cli.wordwrap(text, 10)
      expected = "123456789\n123456789\n123456789!"
      assert.is.same(result, expected)

      -- exact length + 1 overflow
      result = cli.wordwrap(text, 9)
      expected = "123456789\n123456789\n123456789\n!"
      assert.is.same(result, expected)

      result = cli.wordwrap(text, 9, nil, true)
      expected = "123456789\n123456789\n123456789!"
      assert.is.same(result, expected)

      result = cli.wordwrap(text, 8)
      expected = "12345678\n9\n12345678\n9\n12345678\n9!"
      assert.is.same(result, expected)
    end)

  end)   -- private functions
  
  describe("testing public functions", function()

    setup(function()
      package.loaded.cliargs = false  -- Busted uses it, but must force to reload to test it with _TEST
      cli = require("cliargs")
    end)

    teardown(function()
    end)
    
    before_each(function()
      cli.optional = {}
      cli.required = {}
    end)

    after_each(function()
    end)

    it("tests the add_arg() method", function()
      -- takes: key, descr, ref
      local key, desc, ref = "argname", "thedescription", "reference"
      cli:add_arg(key, desc, ref)
      assert.are.equal(cli.required[1].key, key)
      assert.are.equal(cli.required[1].desc, desc)
      assert.are.equal(cli.required[1].ref, ref)
    end)
    
    it("tests add_opt() with short-key", function()
      -- takes: key, descr, ref, default
      local key, desc, ref, default = "-i", "thedescription", "reference", "default"
      cli:add_opt(key, desc, ref, default)
      assert.are.equal(cli.optional[1].key, "i")
      assert.are.equal(cli.optional[1].expanded_key, "")
      assert.are.equal(cli.optional[1].desc, desc)
      assert.are.equal(cli.optional[1].flag, true)
      assert.are.equal(cli.optional[1].ref, ref)
      assert.are.equal(cli.optional[1].default, false) -- no value = flag type option, hence false
    end)
    
    it("tests add_opt() with short-key & value", function()
      -- takes: key, descr, ref, default
      local key, desc, ref, default = "-i VALUE", "thedescription", "reference", "default"
      cli:add_opt(key, desc, ref, default)
      assert.are.equal(cli.optional[1].key, "i")
      assert.are.equal(cli.optional[1].expanded_key, "")
      assert.are.equal(cli.optional[1].desc, desc)
      assert.are.equal(cli.optional[1].flag, false)
      assert.are.equal(cli.optional[1].ref, ref)
      assert.are.equal(cli.optional[1].default, default)
    end)
    
    it("tests add_opt() with short + expanded-key", function()
      -- takes: key, descr, ref, default
      local key, desc, ref, default = "-i, --insert", "thedescription", "reference", "default"
      cli:add_opt(key, desc, ref, default)
      assert.are.equal(cli.optional[1].key, "i")
      assert.are.equal(cli.optional[1].expanded_key, "insert")
      assert.are.equal(cli.optional[1].desc, desc)
      assert.are.equal(cli.optional[1].flag, true)
      assert.are.equal(cli.optional[1].ref, ref)
      assert.are.equal(cli.optional[1].default, false) -- no value = flag type option, hence false
    end)
    
    it("tests add_opt() with short + expanded-key & value", function()
      -- takes: key, descr, ref, default
      local key, desc, ref, default = "-i, --insert=VALUE", "thedescription", "reference", "default"
      cli:add_opt(key, desc, ref, default)
      assert.are.equal(cli.optional[1].key, "i")
      assert.are.equal(cli.optional[1].expanded_key, "insert")
      assert.are.equal(cli.optional[1].desc, desc)
      assert.are.equal(cli.optional[1].flag, false)
      assert.are.equal(cli.optional[1].ref, ref)
      assert.are.equal(cli.optional[1].default, default)
    end)
    
    it("tests add_opt() with only expanded-key", function()
      -- takes: key, descr, ref, default
      local key, desc, ref, default = "--insert", "thedescription", "reference", "default"
      cli:add_opt(key, desc, ref, default)
      assert.are.equal(cli.optional[1].key, "")
      assert.are.equal(cli.optional[1].expanded_key, "insert")
      assert.are.equal(cli.optional[1].desc, desc)
      assert.are.equal(cli.optional[1].flag, true)
      assert.are.equal(cli.optional[1].ref, ref)
      assert.are.equal(cli.optional[1].default, false) -- no value = flag type option, hence false
    end)
    
    it("tests add_opt() with only expanded-key & value", function()
      -- takes: key, descr, ref, default
      local key, desc, ref, default = "--insert=VALUE", "thedescription", "reference", "default"
      cli:add_opt(key, desc, ref, default)
      assert.are.equal(cli.optional[1].key, "")
      assert.are.equal(cli.optional[1].expanded_key, "insert")
      assert.are.equal(cli.optional[1].desc, desc)
      assert.are.equal(cli.optional[1].flag, false)
      assert.are.equal(cli.optional[1].ref, ref)
      assert.are.equal(cli.optional[1].default, default)
    end)
    
    it("tests add_opt() with short-key, no reference", function()
      -- takes: key, descr, ref, default
      local key, desc, ref, default = "-i VALUE", "thedescription", nil, "default"
      cli:add_opt(key, desc, ref, default)
      assert.are.equal(cli.optional[1].ref, "i")
    end)
    
    it("tests add_opt() with expanded-key, no reference", function()
      -- takes: key, descr, ref, default
      local key, desc, ref, default = "-i, --insert=VALUE", "thedescription", nil, "default"
      cli:add_opt(key, desc, ref, default)
      assert.are.equal(cli.optional[1].ref, "insert")
    end)
      
    it("tests add_opt() with short and expanded-key, no comma between them", function()
      -- takes: key, descr, ref, default
      local key, desc, ref, default = "-i --insert=VALUE", "thedescription", nil, "default"
      cli:add_opt(key, desc, ref, default)
      assert.are.equal(cli.optional[1].key, "i")
      assert.are.equal(cli.optional[1].expanded_key, "insert")
    end)
      
    it("tests add_flag() for setting default value", function()
      -- takes: key, descr, ref
      local key, desc, ref = "-i, --insert", "thedescription", "reference"
      cli:add_flag(key, desc, ref)
      assert.are.equal(cli.optional[1].flag, true)
      assert.are.equal(cli.optional[1].default, false)  -- boolean because its a flag
    end)

    it("tests add_flag() to error-out when providing a value", function()
      -- takes: key, descr, ref
      local key, desc, ref = "-i, --insert=VALUE", "thedescription", "reference"
      assert.is.error(function() cli:add_flag(key, desc, ref) end)  --'=VALUE' is not allowed for a flag
    end)

    it("tests add_arg() with a duplicate argument", function()
      -- takes: key, descr, ref
      local key, desc, ref = "argname", "thedescription", "reference"
      cli:add_arg(key, desc, ref)
      assert.are.equal(cli.required[1].key, key) -- make sure it got added
      assert.is.error(function() cli:add_arg(key, desc, ref) end) -- this should blow up
    end)
    
    it("tests add_opt() with a duplicate argument", function()
      -- takes: key, descr, ref
      local key, desc, ref, default = "-i", "thedescription", "reference", "default"
      cli:add_opt(key, desc, ref, default)
      assert.are.equal(cli.optional[1].key, "i") -- make sure it got added
      assert.are.equal(cli.optional[1].expanded_key, "")
      assert.is.error(function() cli:add_opt(key, desc, ref, default) end) -- this should blow up
    end)

    describe("testing the 'noprint' options", function()

      local old_print, touched
    
      setup(function()
        old_print = print
        local interceptor = function(...)
          touched = true
          return old_print(...)
        end
        print = interceptor
      end)
      
      teardown(function()
        print = (old_print or print)
      end)

      before_each(function()
        touched = nil
      end)
      
      after_each(function()
      end)

      it("tests whether print_help() does not print anything, if noprint is set (includes print_usage())", function()
        local key, desc, ref, default = "-a", "thedescription", "reference", "default"
        local noprint = true
        cli:add_opt(key, desc, ref, default)
        local res = cli:print_help(noprint)
        assert.is.equal(type(res), "string")
        assert.is.equal(nil, touched)
      end)
      
      it("tests whether a parsing error through cli_error() does not print anything, if noprint is set", function()
        -- generate a parse error
        local key, desc, ref = "ARGUMENT", "thedescription", "reference"
        cli:add_opt(key, desc, ref)
        local noprint = true
        arg = {"arg1", "arg2", "arg3", "arg4"} -- should fail for too many arguments
        local res, err = cli:parse(noprint)
        assert.is.equal(nil, res)
        assert.is.equal(type(err), "string")
        assert.is.equal(nil, touched)
      end)
      
    end)

  end)   -- public functions
  
end)