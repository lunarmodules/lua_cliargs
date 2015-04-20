-- luacheck: globals describe it before_each setup teardown, ignore dump print

describe("Testing cliargs library methods/functions", function()
  local cli

  setup(function()
    -- if cli then cli:cleanup() end
    cli = require("cliargs.core")()
  end)

  describe("testing private functions", function()
    it("tests the optarg() method", function()
      local key, desc, default, maxcount = "LastArg", "The lastarg description", "lastarg default", 3
      local expected = { key = key, desc = desc, default = default, maxcount = maxcount}
      cli:optarg(key, desc, default, maxcount)
      assert.are.same(cli.optargument, expected)
    end)

  end)   -- private functions

  describe("testing public functions", function()
    before_each(function()
      cli.optional = {}
      cli.required = {}
    end)

    it("tests the add_argument() method", function()
      -- takes: key, descr
      local key, desc = "argname", "thedescription"
      cli:add_argument(key, desc)
      assert.are.equal(cli.required[1].key, key)
      assert.are.equal(cli.required[1].desc, desc)
    end)

    describe("#add_option()", function()
      describe("given a value indicator", function()
        it("should work with only a short-key", function()
          -- takes: key, descr, default
          local key, desc, default = "-i VALUE", "thedescription", "default"
          cli:add_option(key, desc, default)
          assert.are.equal(cli.optional[1].key, "i")
          assert.are.equal(cli.optional[1].desc, desc)
          assert.are.equal(cli.optional[1].flag, false)
          assert.are.equal(cli.optional[1].default, default)
        end)

        it("should work with a short-key that is longer than 1 character", function()
          local key, desc, default = "-Xassembler OPTIONS", "Pass <arg> on to the assembler", ""

          cli:add_option(key, desc, default)

          assert.are.equal(cli.optional[1].key, "Xassembler")
          assert.are.equal(cli.optional[1].desc, desc)
          assert.are.equal(cli.optional[1].flag, false)
          assert.are.equal(cli.optional[1].default, default)
        end)

        it("should work with only expanded-key", function()
          -- takes: key, descr, default
          local key, desc, default = "--insert=VALUE", "thedescription", "default"
          cli:add_option(key, desc, default)
          assert.are.equal(cli.optional[1].expanded_key, "insert")
          assert.are.equal(cli.optional[1].desc, desc)
          assert.are.equal(cli.optional[1].flag, false)
          assert.are.equal(cli.optional[1].default, default)
        end)

        it("should work with combined short + expanded-key", function()
          -- takes: key, descr, default
          local key, desc, default = "-i, --insert=VALUE", "thedescription", "default"
          cli:add_option(key, desc, default)
          assert.are.equal(cli.optional[1].key, "i")
          assert.are.equal(cli.optional[1].expanded_key, "insert")
          assert.are.equal(cli.optional[1].desc, desc)
          assert.are.equal(cli.optional[1].flag, false)
          assert.are.equal(cli.optional[1].default, default)
        end)

        it("should work with combined short + expanded-key, no comma between them", function()
          -- takes: key, descr, default
          local key, desc, default = "-i --insert=VALUE", "thedescription", "default"
          cli:add_option(key, desc, default)
          assert.are.equal(cli.optional[1].key, "i")
          assert.are.equal(cli.optional[1].expanded_key, "insert")
        end)
      end)

      describe("given no value indicator (implicit flags)", function()
        it("should work with a short-key", function()
          -- takes: key, descr, default
          local key, desc, default = "-i", "thedescription", "default"
          cli:add_option(key, desc, default)
          assert.are.equal(cli.optional[1].key, "i")
          assert.are.equal(cli.optional[1].desc, desc)
          assert.are.equal(cli.optional[1].flag, true)
          assert.are.equal(cli.optional[1].default, nil) -- no value = flag type option, hence nil
        end)

        it("should work with a short-key that is longer than 1 character", function()
          -- takes: key, descr, default
          local key, desc, default = "-Wno-unsigned", "thedescription", nil
          cli:add_option(key, desc, default)

          assert.are.equal(cli.optional[1].key, "Wno-unsigned")
          assert.are.equal(cli.optional[1].desc, desc)
          assert.are.equal(cli.optional[1].flag, true)
          assert.are.equal(cli.optional[1].default, nil) -- no value = flag type option, hence nil
        end)

        it("should work with only expanded-key", function()
          -- takes: key, descr, default
          local key, desc, default = "--insert", "thedescription", "default"
          cli:add_option(key, desc, default)
          assert.are.equal(cli.optional[1].expanded_key, "insert")
          assert.are.equal(cli.optional[1].desc, desc)
          assert.are.equal(cli.optional[1].flag, true)
          assert.are.equal(cli.optional[1].default, nil) -- no value = flag type option, hence nil
        end)

        it("should work with combined short + expanded-key", function()
          -- takes: key, descr, default
          local key, desc, default = "-i, --insert", "thedescription", "default"
          cli:add_option(key, desc, default)
          assert.are.equal(cli.optional[1].key, "i")
          assert.are.equal(cli.optional[1].expanded_key, "insert")
          assert.are.equal(cli.optional[1].desc, desc)
          assert.are.equal(cli.optional[1].flag, true)
          assert.are.equal(cli.optional[1].default, nil) -- no value = flag type option, hence nil
        end)
      end)
    end)

    it("tests add_flag() for setting default value", function()
      -- takes: key, descr
      local key, desc = "-i, --insert", "thedescription"
      cli:add_flag(key, desc)
      assert.are.equal(cli.optional[1].flag, true)
      assert.are.equal(cli.optional[1].default, nil)
    end)

    it("tests add_flag() to error-out when providing a value", function()
      -- takes: key, descr
      local key, desc = "-i, --insert=VALUE", "thedescription"
      assert.is.error(function() cli:add_flag(key, desc) end)  --'=VALUE' is not allowed for a flag
    end)

    it("tests add_argument() with a duplicate argument", function()
      -- takes: key, descr
      local key, desc = "argname", "thedescription"
      cli:add_argument(key, desc)
      assert.are.equal(cli.required[1].key, key) -- make sure it got added
      assert.is.error(function() cli:add_argument(key, desc) end) -- this should blow up
    end)

    it("tests add_flag() with a duplicate argument", function()
      -- takes: key, descr
      local key, desc, default = "--no-insert", "thedescription", nil
      cli:add_flag(key, desc, default)
      assert.are.equal(cli.optional[1].expanded_key, "no-insert") -- make sure it got added
      assert.is.error(function() cli:add_flag("--[no-]insert", desc) end) -- this should blow up
    end)

    it("tests add_option() with a duplicate flag", function()
      -- takes: key, descr
      local key, desc, default = "-i, --[no-]insert", "thedescription", true
      cli:add_flag(key, desc, default)
      assert.are.equal(cli.optional[1].key, "i") -- make sure it got added
      assert.are.equal(cli.optional[1].expanded_key, "insert") -- make sure it got added
      assert.is.error(function() cli:add_option("--no-insert", desc, '') end) -- this should blow up
      assert.is.error(function() cli:add_option("--insert", desc, '') end) -- this should blow up
    end)

    it("tests add_option() with a duplicate argument", function()
      -- takes: key, descr
      local key, desc, default = "-i", "thedescription", "default"
      cli:add_option(key, desc, default)
      assert.are.equal(cli.optional[1].key, "i") -- make sure it got added
      assert.is.error(function() cli:add_option(key, desc, default) end) -- this should blow up
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

      it("tests whether print_help() does not print anything, if noprint is set (includes print_usage())", function()
        local key, desc, default = "-a", "thedescription", "default"
        local noprint = true
        cli:add_option(key, desc, default)
        local res = cli:print_help(noprint)
        assert.is.equal(type(res), "string")
        assert.is.equal(nil, touched)
      end)

      it("tests whether a parsing error through cli_error() does not print anything, if noprint is set", function()
        -- generate a parse error
        local key, desc = "ARGUMENT", "thedescription"
        cli:add_option(key, desc)
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
