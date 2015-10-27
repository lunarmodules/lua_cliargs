local helpers = require 'spec_helper'
local cliargs = require 'cliargs'

describe('cliargs', function()
  setup(function()
    cliargs:flag('--foo', '...')
  end)

  after_each(function()
    cliargs = require 'cliargs'
  end)

  it('does not blow up!', function()
  end)

  it('yields a default core instance', function()
    assert.equal(type(cliargs), 'table')
  end)

  describe('#parse', function()
    it('works', function()
      local args

      assert.has_no_errors(function()
        args = cliargs:parse({})
      end)

      assert.equal(type(args), 'table')
    end)

    it('propagates errors', function()
      local args, err = cliargs:parse({ '--bar' }, true)

      assert.equal(type(err), 'string')
      assert.is_nil(args)
    end)
  end)

  describe('#cleanup', function()

    it('exposes a cleanup routine', function()
      assert.equal(type(cliargs.cleanup), 'function')
    end)

    it('actually cleans up', function()
      local modules = {}

      for k, _ in pairs(package.loaded) do
        if k:match('cliargs') then
          table.insert(modules, k)
        end
      end

      assert.is_not_equal(#modules, 0)
      assert.is_not_nil(package.loaded['cliargs'])

      cliargs:cleanup()

      for k, _ in pairs(modules) do
        assert.is_nil(package.loaded[k])
      end

      assert.is_nil(package.loaded['cliargs'])
    end)
  end)
end)