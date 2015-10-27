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
      assert.spy(s).called_with(match.is_string(), match.is_nil())
    end)
  end)

  describe('#parse', function()
    context('when invoked without the arguments table', function()
      it('uses the global _G["arg"] one', function()
        _G["arg"] = {"--quiet"}

        cli:option('--quiet', '...')
        local args = cli:parse()

        assert.equal(args.quiet, true)
      end)
    end)

    it('does not mutate the argument table', function()
      local arguments = { "--quiet" }
      cli:option('--quiet', '...')

      cli:parse(arguments)

      assert.equal(#arguments, 1)
      assert.equal(arguments[1], "--quiet")
    end)

    describe('displaying the help listing', function()
      before_each(function()
        cli:argument('INPUT', '...')
        cli:flag('--quiet', '...')
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

    context('when @silent is on', function()
      it("does not print the help listing to STDOUT", function()
        local res = cli:print_help(true)

        assert.equal(type(res), "string")
        assert.equal(touched, false)
      end)

      it("does not print errors to STDOUT", function()
        cli:option("ARGUMENT", '...')

        local args = { "arg1", "arg2" } -- should fail for too many arguments
        local res, err = cli:parse(args, true)

        assert.is.equal(nil, res)
        assert.is.equal(type(err), "string")
        assert.is.equal(false, touched)
      end)
    end)
  end)

  describe('#parse - the --__DUMP__ special option', function()
    it('dumps the state and errors out', function()
      stub(cli.printer, 'print')

      cli:set_error_handler(function(msg) error(msg) end)

      cli:argument('OUTPUT', '...')
      cli:splat('INPUTS', '...', nil, 5)
      cli:option('-c, --compress=VALUE', '...')
      cli:flag('-q, --quiet', '...', true)

      assert.error_matches(function()
        cli:parse({'--__DUMP__', '/tmp/out', '/tmp/in.1', '/tmp/in.2', '/tmp/in.3' })
      end, 'commandline dump created')
    end)
  end)

  describe('#redefine_default', function()
    it('allows me to change the default for an optargument', function()
      cli:splat('ROOT', '...', 'foo')
      assert.equal(cli:parse({}).ROOT, 'foo')

      cli:redefine_default('ROOT', 'bar')
      assert.equal(cli:parse({}).ROOT, 'bar')
    end)

    it('allows me to change the default for an option', function()
      cli:option('-c, --compress=VALUE', '...', 'lzma')
      assert.equal(cli:parse({}).compress, 'lzma')

      cli:redefine_default('compress', 'bz2')
      assert.equal(cli:parse({}).compress, 'bz2')
    end)

    it('allows me to change the default for a flag', function()
      cli:flag('-q, --quiet', '...', false)
      assert.equal(cli:parse({}).quiet, false)

      cli:redefine_default('quiet', true)
      assert.equal(cli:parse({}).quiet, true)
    end)

    it('validates the new default value for an option', function()
      cli:option('-c VALUE', '...', 'lzma')

      assert.error_matches(function()
        cli:redefine_default('c', function() end)
      end, 'Default argument')
    end)

    it('validates the new default value for a flag', function()
      cli:option('-q', '...', true)

      assert.error_matches(function()
        cli:redefine_default('q', 'break break break')
      end, 'Default argument')
    end)
  end)

  describe('#load_defaults', function()
    it('works', function()
      cli:option('-c, --compress=VALUE', '...', 'lzma')
      cli:flag('-q, --quiet', '...', false)

      cli:load_defaults({
        compress = 'bz2',
        quiet = true
      })

      local args, err = cli:parse({})

      assert.equal(err, nil)
      assert.same(args, {
        c = 'bz2',
        compress = 'bz2',
        q = true,
        quiet = true
      })
    end)

    it('stores arbitrary options', function()
      cli:load_defaults({ sources = { 'file1.c' } })
      assert.same(cli:get_arbitrary_options(), { sources = { 'file1.c' } })
    end)
  end)
end)