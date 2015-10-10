require "spec_helper"

describe("cliargs::core", function()
  local cli

  before_each(function()
    cli = require("cliargs.core")()
  end)

  describe("#parse - the @noprint option", function()
    local old_print, touched

    setup(function()
      old_print = print

      local interceptor = function(...)
        touched = true
        return old_print(...)
      end

      _G['print'] = interceptor
    end)

    teardown(function()
      _G['print'] = (old_print or print)
    end)

    before_each(function()
      touched = false
    end)

    context('when @noprint is on', function()
      it("does not print the help listing to STDOUT", function()
        local res = cli:print_help(true)

        assert.equal(type(res), "string")
        assert.equal(touched, false)
      end)

      it("does not print errors to STDOUT", function()
        cli:add_option("ARGUMENT", '...')

        local args = { "arg1", "arg2" } -- should fail for too many arguments
        local res, err = cli:parse(args, true)

        assert.is.equal(nil, res)
        assert.is.equal(type(err), "string")
        assert.is.equal(false, touched)
      end)
    end)
  end)
end)