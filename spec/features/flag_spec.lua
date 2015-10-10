local helpers = require("spec_helper")

describe("cliargs - flags", function()
  local cli

  before_each(function()
    cli = require("cliargs.core")()
    cli.on_error = error
  end)

  describe('defining flags', function()
    it('works', function()
      assert.has_no_errors(function()
        cli:add_flag('--quiet', 'suppress output')
      end)
    end)

    it('requires a key', function()
      assert.error_matches(function()
        cli:add_flag()
      end, 'Key and description are mandatory arguments')
    end)

    it('requires a description', function()
      assert.error_matches(function()
        cli:add_flag('--quiet')
      end, 'Key and description are mandatory arguments')
    end)

    it('rejects a value label', function()
      assert.error_matches(function()
        cli:add_flag('--quiet=QUIET', '...')
      end, 'A flag type option cannot have a value set')
    end)

    it('rejects a duplicate flag', function()
      cli:add_flag('--quiet', '...')

      assert.error_matches(function()
        cli:add_flag('--quiet', '...')
      end, 'Duplicate')
    end)
  end)

  describe('parsing', function()
    it('works with only a short key: -v', function()
      cli:add_flag('-v', '...')
      assert.equal(helpers.parse(cli, '-v').v, true)
    end)

    it('works with only an expanded key: --verbose', function()
      cli:add_flag('--verbose', '...')
      assert.equal(helpers.parse(cli, '--verbose').verbose, true)
    end)

    it('works with both: -v, --verbose', function()
      cli:add_flag('-v, --verbose', '...')
      assert.equal(helpers.parse(cli, '--verbose').verbose, true)
      assert.equal(helpers.parse(cli, '-v').verbose, true)
    end)

    context('given a default value', function()
      it('accepts a nil', function()
        assert.has_no_errors(function()
          cli:add_flag('--quiet', '...', nil)
        end)

        assert.equal(helpers.parse(cli, '').quiet, nil)
      end)

      it('accepts a true value', function()
        assert.has_no_errors(function()
          cli:add_flag('--quiet', '...', true)
        end)

        assert.equal(helpers.parse(cli, '').quiet, true)
      end)

      it('accepts a false value', function()
        assert.has_no_errors(function()
          cli:add_flag('--quiet', '...', false)
        end)

        assert.equal(helpers.parse(cli, '').quiet, false)
      end)

      it('rejects everything else', function()
        assert.error_matches(function()
          cli:add_flag('--quiet', '...', 'no')
        end, 'expected a boolean or nil')
      end)
    end)

    context('given an unknown flag', function()
      it('bails', function()
        stub(cli, 'on_error')

        helpers.parse(cli, '--asdf', true)

        assert.match('unknown', helpers.get_stub_call_arg(cli.on_error, 1, 1))
      end)
    end)
  end)

  describe('parsing an option with a short key longer than 1 char', function()
    before_each(function()
      cli:add_flag('-Wno-unsigned', '...')
    end)

    it('works', function()
      local args = helpers.parse(cli, '-Wno-unsigned')
      assert.equal(args['Wno-unsigned'], true)
    end)
  end)

  describe('parsing negatable flags', function()
    context('when a flag is negatable (-q, --[no-]quiet)', function()
      before_each(function()
        cli:add_flag('-q, --[no-]quiet', '...')
      end)

      it('works', function()
        local args = helpers.parse(cli, '--no-quiet')
        assert.equal(args.quiet, false)
      end)

      it('overrides the original version (-q --no-quiet => false)', function()
        local args = helpers.parse(cli, '-q --no-quiet')
        assert.equal(args.quiet, false)
      end)

      it('ignores the negated version (--no-quiet -q => true)', function()
        local args = helpers.parse(cli, '--no-quiet -q')
        assert.equal(args.quiet, true)
      end)
    end)

    context('when a flag is NON-negatable (-q, --quiet)', function()
      before_each(function()
        cli:add_flag('-q, --quiet', '...')
      end)

      it('bails', function()
        assert.error_matches(function()
          helpers.parse(cli, '--no-quiet')
        end, 'may not be negated')
      end)
    end)
  end)

  describe('@callback', function()
    local call_args
    local function capture(key, value, altkey)
      table.insert(call_args, { key, value, altkey })
    end

    context('given a single flag', function()
      before_each(function()
        call_args = {}

        cli:add_flag('-q, --quiet', '...', nil, capture)
      end)

      it('invokes the callback when the flag is parsed', function()
        helpers.parse(cli, '--quiet')

        assert.equal(call_args[1][1], 'quiet')
        assert.equal(call_args[1][2], true)
        assert.equal(call_args[1][3], 'q')
      end)
    end)

    context('given a negated flag', function()
        before_each(function()
        call_args = {}

        cli:add_flag('-q, --[no-]quiet', '...', nil, capture)
      end)

      it('invokes the callback when the flag is parsed', function()
        helpers.parse(cli, '--no-quiet')

        assert.equal(call_args[1][1], 'quiet')
        assert.equal(call_args[1][2], false)
        assert.equal(call_args[1][3], 'q')
      end)
    end)

    context('given multiple flags', function()
      before_each(function()
        call_args = {}

        cli:add_flag('-q, --quiet', '...', nil, capture)
        cli:add_flag('--verbose', '...', nil, capture)
      end)

      it('invokes the callback for each flag parsed', function()
        helpers.parse(cli, '--quiet --verbose')

        assert.equal(call_args[1][1], 'quiet')
        assert.equal(call_args[1][2], true)
        assert.equal(call_args[1][3], 'q')

        assert.equal(call_args[2][1], 'verbose')
        assert.equal(call_args[2][2], true)
        assert.equal(call_args[2][3], nil)
      end)
    end)
  end)
end)