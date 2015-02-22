
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
      _G._TEST = true
      package.loaded.cliargs = nil  -- Busted uses it, but must force to reload to test it with _TEST
      cli = require("cliargs")
    end)

    teardown(function()
      _G._TEST = nil
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

    it("tests the optarg() method", function()
      local key, desc, default, maxcount = "LastArg", "The lastarg description", "lastarg default", 3
      local expected = { key = key, desc = desc, default = default, maxcount = maxcount}
      cli:optarg(key, desc, default, maxcount)
      assert.are.same(cli.optargument, expected)
    end)

  end)   -- private functions

  describe("testing public functions", function()

    setup(function()
      _G._TEST = true
      package.loaded.cliargs = nil  -- Busted uses it, but must force to reload to test it with _TEST
      cli = require("cliargs")
    end)

    teardown(function()
      _G._TEST = nil
    end)

    before_each(function()
      cli.optional = {}
      cli.required = {}
    end)

    after_each(function()
    end)

    it("tests the add_arg() method", function()
      -- takes: key, descr
      local key, desc = "argname", "thedescription"
      cli:add_arg(key, desc)
      assert.are.equal(cli.required[1].key, key)
      assert.are.equal(cli.required[1].desc, desc)
    end)

    describe("#add_opt()", function()
      describe("given a value indicator", function()
        it("should work with only a short-key", function()
          -- takes: key, descr, default
          local key, desc, default = "-i VALUE", "thedescription", "default"
          cli:add_opt(key, desc, default)
          assert.are.equal(cli.optional[1].key, "i")
          --assert.are.equal(cli.optional[1].expanded_key, "")
          assert.are.equal(cli.optional[1].desc, desc)
          assert.are.equal(cli.optional[1].flag, false)
          assert.are.equal(cli.optional[1].default, default)
        end)

        it("should work with a short-key that is longer than 1 character", function()
          local key, desc, default = "-Xassembler OPTIONS", "Pass <arg> on to the assembler", ""

          cli:add_opt(key, desc, default)

          assert.are.equal(cli.optional[1].key, "Xassembler")
          assert.are.equal(cli.optional[1].desc, desc)
          assert.are.equal(cli.optional[1].flag, false)
          assert.are.equal(cli.optional[1].default, default)
        end)

        it("should work with only expanded-key", function()
          -- takes: key, descr, default
          local key, desc, default = "--insert=VALUE", "thedescription", "default"
          cli:add_opt(key, desc, default)
          --assert.are.equal(cli.optional[1].key, "")
          assert.are.equal(cli.optional[1].expanded_key, "insert")
          assert.are.equal(cli.optional[1].desc, desc)
          assert.are.equal(cli.optional[1].flag, false)
          assert.are.equal(cli.optional[1].default, default)
        end)

        it("should work with combined short + expanded-key", function()
          -- takes: key, descr, default
          local key, desc, default = "-i, --insert=VALUE", "thedescription", "default"
          cli:add_opt(key, desc, default)
          assert.are.equal(cli.optional[1].key, "i")
          assert.are.equal(cli.optional[1].expanded_key, "insert")
          assert.are.equal(cli.optional[1].desc, desc)
          assert.are.equal(cli.optional[1].flag, false)
          assert.are.equal(cli.optional[1].default, default)
        end)

        it("should work with combined short + expanded-key, no comma between them", function()
          -- takes: key, descr, default
          local key, desc, default = "-i --insert=VALUE", "thedescription", "default"
          cli:add_opt(key, desc, default)
          assert.are.equal(cli.optional[1].key, "i")
          assert.are.equal(cli.optional[1].expanded_key, "insert")
        end)
      end)

      describe("given no value indicator (implicit flags)", function()
        it("should work with a short-key", function()
          -- takes: key, descr, default
          local key, desc, default = "-i", "thedescription", "default"
          cli:add_opt(key, desc, default)
          assert.are.equal(cli.optional[1].key, "i")
          --assert.are.equal(cli.optional[1].expanded_key, "")
          assert.are.equal(cli.optional[1].desc, desc)
          assert.are.equal(cli.optional[1].flag, true)
          assert.are.equal(cli.optional[1].default, false) -- no value = flag type option, hence false
        end)

        it("should work with a short-key that is longer than 1 character", function()
          pending("https://github.com/amireh/lua_cliargs/issues/36")

          -- takes: key, descr, default
          local key, desc, default = "-Wno-unsigned", "thedescription"
          cli:add_opt(key, desc, default)
          dump(cli.optional[1])
          assert.are.equal(cli.optional[1].key, "Wno-unsigned")
          --assert.are.equal(cli.optional[1].expanded_key, "")
          assert.are.equal(cli.optional[1].desc, desc)
          assert.are.equal(cli.optional[1].flag, true)
          assert.are.equal(cli.optional[1].default, false) -- no value = flag type option, hence false
        end)

        it("should work with only expanded-key", function()
          -- takes: key, descr, default
          local key, desc, default = "--insert", "thedescription", "default"
          cli:add_opt(key, desc, default)
          --assert.are.equal(cli.optional[1].key, "")
          assert.are.equal(cli.optional[1].expanded_key, "insert")
          assert.are.equal(cli.optional[1].desc, desc)
          assert.are.equal(cli.optional[1].flag, true)
          assert.are.equal(cli.optional[1].default, false) -- no value = flag type option, hence false
        end)

        it("should work with combined short + expanded-key", function()
          -- takes: key, descr, default
          local key, desc, default = "-i, --insert", "thedescription", "default"
          cli:add_opt(key, desc, default)
          assert.are.equal(cli.optional[1].key, "i")
          assert.are.equal(cli.optional[1].expanded_key, "insert")
          assert.are.equal(cli.optional[1].desc, desc)
          assert.are.equal(cli.optional[1].flag, true)
          assert.are.equal(cli.optional[1].default, false) -- no value = flag type option, hence false
        end)
      end)
    end)

    it("tests add_flag() for setting default value", function()
      -- takes: key, descr
      local key, desc = "-i, --insert", "thedescription"
      cli:add_flag(key, desc)
      assert.are.equal(cli.optional[1].flag, true)
      assert.are.equal(cli.optional[1].default, false)  -- boolean because its a flag
    end)

    it("tests add_flag() to error-out when providing a value", function()
      -- takes: key, descr
      local key, desc = "-i, --insert=VALUE", "thedescription"
      assert.is.error(function() cli:add_flag(key, desc) end)  --'=VALUE' is not allowed for a flag
    end)

    it("tests add_arg() with a duplicate argument", function()
      -- takes: key, descr
      local key, desc = "argname", "thedescription"
      cli:add_arg(key, desc)
      assert.are.equal(cli.required[1].key, key) -- make sure it got added
      assert.is.error(function() cli:add_arg(key, desc) end) -- this should blow up
    end)

    it("tests add_opt() with a duplicate argument", function()
      -- takes: key, descr
      local key, desc, default = "-i", "thedescription", "default"
      cli:add_opt(key, desc, default)
      assert.are.equal(cli.optional[1].key, "i") -- make sure it got added
      --assert.are.equal(cli.optional[1].expanded_key, "")
      assert.is.error(function() cli:add_opt(key, desc, default) end) -- this should blow up
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
        local key, desc, default = "-a", "thedescription", "default"
        local noprint = true
        cli:add_opt(key, desc, default)
        local res = cli:print_help(noprint)
        assert.is.equal(type(res), "string")
        assert.is.equal(nil, touched)
      end)

      it("tests whether a parsing error through cli_error() does not print anything, if noprint is set", function()
        -- generate a parse error
        local key, desc = "ARGUMENT", "thedescription"
        cli:add_opt(key, desc)
        local noprint = true
        local args = {"arg1", "arg2", "arg3", "arg4"} -- should fail for too many arguments
        local res, err = cli:parse(args, noprint)
        assert.is.equal(nil, res)
        assert.is.equal(type(err), "string")
        assert.is.equal(nil, touched)
      end)

    end)

  end)   -- public functions

end)
