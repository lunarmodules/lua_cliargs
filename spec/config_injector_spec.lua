
local config_injector = require 'cliargs.config_injector'

describe("cliargs.config_injector", function()
  local cli

  before_each(function()
    cli = require("cliargs.core")()
  end)

  describe('#from_object', function()
    it('works', function()
      cli:add_option('-c, --compress=VALUE', '...', 'lzma')
      cli:add_flag('-q, --quiet', '...', false)

      cli:add_flag('--inject', '...', nil, function()
        return config_injector.from_object(cli, {
          compress = 'bz2',
          quiet = true
        })
      end)

      local args, err = cli:parse({ '--inject' })

      assert.equal(err, nil)
      assert.same(args, {
        c = 'bz2',
        compress = 'bz2',
        q = true,
        quiet = true,
        inject = true
      })
    end)
  end)

  describe('#from_json', function()
    it('works', function()
      cli:add_option('-c, --compress=VALUE', '...', 'lzma')
      cli:add_flag('-q, --quiet', '...', false)

      cli:add_option('--config=FILE', '...', nil, function(_, path)
        return config_injector.from_json(cli, path)
      end)

      local args, err = cli:parse({ '--config', 'spec/fixtures/config.json' })

      assert.equal(err, nil)

      assert.same(args, {
        c = 'bz2',
        compress = 'bz2',
        q = true,
        quiet = true,
        config = 'spec/fixtures/config.json'
      })
    end)
  end)

  describe('#from_ini', function()
    it('works', function()
      cli:add_option('-c, --compress=VALUE', '...', 'lzma')
      cli:add_flag('-q, --quiet', '...', false)
      cli:add_option('--config=FILE', '...', nil, function(_, path)
        return config_injector.from_ini(cli, path, 'cli')
      end)

      local args, err = cli:parse({ '--config', 'spec/fixtures/config.ini' })

      assert.equal(err, nil)

      assert.same(args, {
        c = 'bz2',
        compress = 'bz2',
        q = true,
        quiet = true,
        config = 'spec/fixtures/config.ini'
      })
    end)
  end)

  describe('#from_yaml', function()
    it('works', function()
      cli:add_option('-c, --compress=VALUE', '...', 'lzma')
      cli:add_flag('-q, --quiet', '...', false)
      cli:add_option('--config=FILE', '...', nil, function(_, path)
        return config_injector.from_yaml(cli, path)
      end)

      local args, err = cli:parse({ '--config', 'spec/fixtures/config.yml' })

      assert.equal(err, nil)

      assert.same(args, {
        c = 'bz2',
        compress = 'bz2',
        q = true,
        quiet = true,
        config = 'spec/fixtures/config.yml'
      })
    end)
  end)
end)