local helpers = require("spec_helper")

describe("cliargs - splat arguments", function()
  local cli

  before_each(function()
    cli = require("cliargs.core")()
    cli.on_error = error
  end)

  describe('defining the splat arg', function()
    it('works', function()
      assert.has_no_error(function()
        cli:optarg('SPLAT', 'some repeatable arg')
      end)
    end)

    it('requires a key', function()
      assert.error_matches(function()
        cli:optarg()
      end, 'Key and description are mandatory arguments')
    end)

    it('requires a description', function()
      assert.error_matches(function()
        cli:optarg('SPLAT')
      end, 'Key and description are mandatory arguments')
    end)

    it('rejects multiple definitions', function()
      cli:optarg('SPLAT', 'some repeatable arg')

      assert.error_matches(function()
        cli:optarg('SOME_SPLAT', 'some repeatable arg')
      end, 'Only one splat')
    end)
  end)

  describe('default value', function()
    it('allows me to define a default value', function()
      cli:optarg('SPLAT', 'some repeatable arg', 'foo')
    end)

    it('uses the default value when nothing is passed in', function()
      cli:optarg('SPLAT', 'some repeatable arg', 'foo')
      local args = helpers.parse(cli, '')

      assert.equal(args.SPLAT, 'foo')
    end)

    it('does not use the default value if something was passed in at least once', function()
      cli:optarg('SPLAT', 'some repeatable arg', 'foo', 3)
      local args = helpers.parse(cli, 'asdf')

      assert.equal(args.SPLAT[1], 'asdf')
      assert.equal(args.SPLAT[2], nil)
      assert.equal(args.SPLAT[3], nil)
    end)
  end)

  describe('repetition count', function()
    it('accepts a repetition count', function()
      assert.has_no_error(function()
        cli:optarg('SPLAT', 'some repeatable arg', nil, 2)
      end)
    end)

    it('appends the values to a list', function()
      cli:optarg('SPLAT', 'some repeatable arg', nil, 2)
      local args = helpers.parse(cli, 'a b')

      assert.equal(#args.SPLAT, 2)
      assert.equal(args.SPLAT[1], 'a')
      assert.equal(args.SPLAT[2], 'b')
    end)

    it('bails if more values were passed than acceptable', function()
      cli:optarg('SPLAT', 'foobar', nil, 2)

      assert.error_matches(function()
        helpers.parse(cli, 'a b c')
      end, "bad number of arguments")
    end)
  end)

  context("given a splatarg as the only argument/option", function()
    it("works", function()
      cli:optarg('SPLAT', 'foobar', nil, 1)

      local args = helpers.parse(cli, 'asdf')

      assert.equal(type(args.SPLAT), "string")
      assert.equal(args.SPLAT, "asdf")
    end)
  end)

  describe('@callback', function()
    it('invokes the callback every time a value for the splat arg is parsed', function()
      local call_args = {}

      cli:optarg('SPLAT', 'foobar', nil, 2, function(_, value)
        table.insert(call_args, value)
      end)

      helpers.parse(cli, 'a b')

      assert.equal(#call_args, 2)
      assert.equal(call_args[1], 'a')
      assert.equal(call_args[2], 'b')
    end)
  end)
end)