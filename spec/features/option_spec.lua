local helpers = require("spec_helper")

describe("cliargs - options", function()
  local cli

  before_each(function()
    cli = require("cliargs.core")()
    cli:set_error_handler(function(msg) error(msg) end)
  end)

  describe('defining options', function()
    it('requires a key', function()
      assert.error_matches(function()
        cli:add_option()
      end, 'Key and description are mandatory arguments')
    end)

    it('requires a description', function()
      assert.error_matches(function()
        cli:add_option('--url=URL')
      end, 'Key and description are mandatory arguments')
    end)

    it('works', function()
      assert.has_no_errors(function()
        cli:add_option('--url=URL', '...')
      end)
    end)

    it('rejects a duplicate option', function()
      cli:add_option('--url=URL', '...')

      assert.error_matches(function()
        cli:add_option('--url=URL', '...')
      end, 'Duplicate')
    end)
  end)

  context('given a value indicator (--url=VALUE)', function()
    it('works with only a short key: -u VALUE', function()
      cli:add_option('-u VALUE', '...')
      assert.equal(helpers.parse(cli, '-u something').u, 'something')
    end)

    it('works with only an expanded key: --url=VALUE', function()
      cli:add_option('--url=VALUE', '...')
      assert.equal(helpers.parse(cli, '--url=something').url, 'something')
    end)

    it('works with only an expanded key using space as a delimiter: --url VALUE', function()
      cli:add_option('--url VALUE', '...')
      assert.equal(helpers.parse(cli, '--url something').url, 'something')
    end)

    it('works with both: -u, --url=VALUE', function()
      cli:add_option('-u, --url=VALUE', '...')
      assert.equal(helpers.parse(cli, '--url=something').url, 'something')
      assert.equal(helpers.parse(cli, '-u=something').url, 'something')
    end)

    it('works with both keys and no comma between them: -u --url VALUE', function()
      cli:add_option('-u --url=VALUE', '...')
      assert.equal(helpers.parse(cli, '--url something').url, 'something')
      assert.equal(helpers.parse(cli, '-u    something').url, 'something')
    end)
  end)

  context('given no value indicator (an implicit flag, e.g. --quiet)', function()
    it('proxies to #add_flag', function()
      stub(cli, 'add_flag')

      cli:add_option('-q', '...')

      assert.stub(cli.add_flag).was.called();
    end)
  end)

  describe('parsing', function()
    before_each(function()
      cli:add_option('-s, --source=SOURCE', '...')
    end)

    context('using a -short key and space as a delimiter', function()
      it('works', function()
        local args = helpers.parse(cli, '-s /foo/**/*.lua')
        assert.equal(args.source, '/foo/**/*.lua')
      end)
    end)

    context('using a -short key and = as a delimiter', function()
      it('works', function()
        local args = helpers.parse(cli, '-s=/foo/**/*.lua')
        assert.equal(args.source, '/foo/**/*.lua')
      end)
    end)

    context('using an --expanded-key and space as a delimiter', function()
      it('works', function()
        local args = helpers.parse(cli, '--source /foo/**/*.lua')
        assert.equal(args.source, '/foo/**/*.lua')
      end)
    end)

    context('using an --expanded-key and = as a delimiter', function()
      it('works', function()
        local args = helpers.parse(cli, '--source=/foo/**/*.lua')
        assert.equal(args.source, '/foo/**/*.lua')
      end)
    end)

    context('for an option with a short key longer than 1 char', function()
      before_each(function()
        cli:add_option('-Xassembler OPTIONS', '...')
      end)

      it('works', function()
        local args = helpers.parse(cli, '-Xassembler foo')
        assert.equal(args.Xassembler, 'foo')
      end)
    end)

    context('given multiple values', function()
      before_each(function()
        cli:add_option('-k, --key=OPTIONS', '...', {})
      end)

      it('works', function()
        local args = helpers.parse(cli, '-k 1 --key=3 -k asdf')

        assert.equal(type(args.k), 'table')
        assert.equal(#args.k, 3)
        assert.equal(args.k[1], '1')
        assert.equal(args.k[2], '3')
        assert.equal(args.k[3], 'asdf')
      end)
    end)

    context('given an unknown option', function()
      it('bails', function()
        assert.error_matches(function()
          helpers.parse(cli, '--asdf=jkl;', true)
        end, 'unknown')
      end)
    end)
  end)

  describe('parsing with a default value', function()
    it('accepts a nil', function()
      cli:add_option('--compress=VALUE', '...', nil)
      assert.equal(helpers.parse(cli, '').compress, nil)
    end)

    it('accepts a string', function()
      cli:add_option('--compress=VALUE', '...', 'lzma')
      assert.equal(helpers.parse(cli, '').compress, 'lzma')
    end)

    it('accepts a number', function()
      cli:add_option('--count=VALUE', '...', 5)
      assert.equal(helpers.parse(cli, '').count, 5)
    end)

    it('accepts a boolean', function()
      cli:add_option('--quiet=VALUE', '...', true)
      assert.equal(helpers.parse(cli, '').quiet, true)
    end)

    it('accepts an empty table', function()
      cli:add_option('--sources=VALUE', '...', {})
      assert.same(helpers.parse(cli, '').sources, {})
    end)

    it('lets me override/reset the default value', function()
      cli:add_option('--compress=URL', '...', 'lzma')
      assert.equal(helpers.parse(cli, '--compress=').compress, '')
    end)

    it('rejects everything else', function()
      assert.error_matches(function()
        cli:add_option('--sources=VALUE', '...', { 'asdf' })
      end, 'expected a string, a number, nil, or {}')
    end)
  end)

  describe('@callback', function()
    local call_args
    local function capture(key, value, altkey)
      table.insert(call_args, { key, value, altkey })
    end

    context('given a single option', function()
      before_each(function()
        call_args = {}

        cli:add_option('-c, --compress=VALUE', '...', nil, capture)
      end)

      it('invokes the callback when the option is parsed', function()
        helpers.parse(cli, '--compress=lzma')

        assert.equal(call_args[1][1], 'compress')
        assert.equal(call_args[1][2], 'lzma')
        assert.equal(call_args[1][3], 'c')
      end)
    end)

    context('when the callback returns an error message', function()
      it('propagates the error', function()
        cli:add_option('-c, --compress=VALUE', '...', nil, function()
          return nil, ">>> bad argument <<<"
        end)

        assert.error_matches(function()
          helpers.parse(cli, '-c lzma', true)
        end, '>>> bad argument <<<')
      end)
    end)

    context('given multiple options', function()
      before_each(function()
        call_args = {}

        cli:add_option('-c, --compress=VALUE', '...', nil, capture)
        cli:add_option('--input=PATH', '...', nil, capture)
      end)

      it('invokes the callback for each option parsed', function()
        helpers.parse(cli, '-c lzma --input=/tmp')

        assert.equal(call_args[1][1], 'c')
        assert.equal(call_args[1][2], 'lzma')
        assert.equal(call_args[1][3], 'compress')

        assert.equal(call_args[2][1], 'input')
        assert.equal(call_args[2][2], '/tmp')
        assert.equal(call_args[2][3], nil)
      end)
    end)
  end)
end)