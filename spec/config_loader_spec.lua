require 'spec_helper'
local config_loader = require 'cliargs.config_loader'

odescribe("cliargs.config_loader", function()
  local cli, args, err

  before_each(function()
    cli = require("cliargs.core")()
    cli:flag('-q, --quiet', '...', false)
    cli:option('-c, --compress=VALUE', '...', 'lzma')
    cli:option('--config=FILE', '...', nil, function(_, path)
      cli:load_defaults_from_file(path)
    end)
  end)

  after_each(function()
    assert.equal(err, nil)
    assert.equal(args.c, 'bz2')
    assert.equal(args.compress, 'bz2')
    assert.equal(args.q, true)
    assert.equal(args.quiet, true)
  end)

  describe('#from_json', function()
    it('works', function()
      args, err = cli:parse({ '--config=spec/fixtures/config.json' })
    end)
  end)

  describe('#from_ini', function()
    it('works', function()
      args, err = cli:parse({ '--config=spec/fixtures/config.ini' })
    end)
  end)

  describe('#from_yaml', function()
    it('works', function()
      args, err = cli:parse({ '--config', 'spec/fixtures/config.yml' })
    end)
  end)

  describe('#from_lua', function()
    it('works', function()
      args, err = cli:parse({ '--config', 'spec/fixtures/config.lua' })
    end)
  end)
end)