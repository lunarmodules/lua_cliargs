local helpers = require "spec_helper"

describe("cliargs::core", function()
  local cli

  before_each(function()
    cli = require("cliargs.core")()
  end)

  describe('#set_error_handler', function()
    local match = require("luassert.match")

    it('accepts a custom error handler', function()
      local s = spy.new(function()
      end)

      cli:set_error_handler(s)
      cli:parse({'--quiet'})

      assert.spy(s).called()
      assert.spy(s).called_with(match.is_string(), match.is_table())
    end)
  end)

  describe('#parse', function()
    context('when invoked without the arguments table', function()
      it('uses the global _G["arg"] one', function()
        _G["arg"] = {"--quiet"}

        cli:add_option('--quiet', '...')
        local args = cli:parse()

        assert.equal(args.quiet, true)
      end)
    end)

    it('does not mutate the argument table', function()
      local arguments = { "--quiet" }
      cli:add_option('--quiet', '...')

      local args = cli:parse(arguments)

      assert.equal(#arguments, 1)
      assert.equal(arguments[1], "--quiet")
    end)

    describe('displaying the help listing', function()
      before_each(function()
        cli:add_argument('INPUT', '...')
        cli:add_flag('--quiet', '...')
        stub(cli, 'print_help')
      end)

      after_each(function()
        assert.stub(cli.print_help).called()
      end)

      it('works with --help in the beginning', function()
        helpers.parse(cli, '--help something')
      end)

      it('works with --help in the end of options', function()
        helpers.parse(cli, '--quiet --help something')
      end)

      it('works with --help after an argument', function()
        helpers.parse(cli, '--quiet something --help')
      end)
    end)
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
      cli.silent = true
      touched = false
    end)

    context('when @noprint is on', function()
      before_each(function()
        cli:set_silent(true)
      end)

      it("does not print the help listing to STDOUT", function()
        local res = cli:print_help()

        assert.equal(type(res), "string")
        assert.equal(touched, false)
      end)

      it("does not print errors to STDOUT", function()
        cli:add_option("ARGUMENT", '...')

        local args = { "arg1", "arg2" } -- should fail for too many arguments
        local res, err = cli:parse(args)

        assert.is.equal(nil, res)
        assert.is.equal(type(err), "string")
        assert.is.equal(false, touched)
      end)
    end)
  end)

  describe('#parse - the --__DUMP__ special option', function()
    it('dumps the state and errors out', function()
      cli:set_silent(true)
      cli:set_error_handler(function(msg) error(msg) end)

      assert.error_matches(function()
        cli:parse({'--__DUMP__'})
      end, 'commandline dump created')
    end)
  end)
end)