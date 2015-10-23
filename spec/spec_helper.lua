-- luacheck: ignore 111

local exports = {}
local split = require 'cliargs.utils.split'
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

exports.parse = function(cli, str)
  return cli:parse(split(str, '%s+'))
end

return exports