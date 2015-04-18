local core = require('cliargs.core')()
local unpack = _G.unpack or table.unpack

local cli = setmetatable({},{ __index = core })

function cli:parse(arguments, no_print, dump, no_cleanup)
  local out = { core.parse(self, arguments, no_print, dump) }

  if not no_cleanup then
    cli.cleanup()
  end

  return unpack(out)
end

-- Clean up the entire module (unload the scripts) as it's expected to be
-- discarded after use.
function cli.cleanup()
  for k, v in pairs(package.loaded) do
    if (v == cli) or (k:match('cliargs')) then
      package.loaded[k] = nil
    end
  end

  cli = nil
end

cli._VERSION = "3.0.rc-1"

return cli