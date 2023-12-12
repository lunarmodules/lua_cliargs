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

exports.trim = function(s)
  local lines = split(s, "\n")
  local _

  if #lines == 0 then
    return s
  end

  local padding = lines[1]:find('%S') or 0
  local buffer = ''

  for _, line in pairs(lines) do
    buffer = buffer .. line:sub(padding, -1):gsub("%s+$", '') .. "\n"
  end

  return buffer:gsub("%s+$", '')
end

return exports
