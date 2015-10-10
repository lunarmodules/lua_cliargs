-- luacheck: ignore 111

local exports = {}
local split = require('cliargs.utils.split')
local busted = require 'busted'

function odescribe(desc, runner)
  busted.describe("#only " .. desc, runner)
end

function xdescribe()
end

function oit(desc, runner)
  busted.it("#only " .. desc, runner)
end

function xit(desc, _)
  busted.it(desc)
end

exports.parse = function(cli, str, noprint)
  return cli:parse(split(str, '%s+'), noprint == nil and true or noprint)
end

exports.get_stub_call_arg = function(stub, call_index, arg_index)
  return stub.calls[call_index].vals[arg_index]
end

return exports