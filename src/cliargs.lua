-- luacheck: ignore 212

local core = require('cliargs.core')()
local unpack = _G.unpack or table.unpack -- luacheck: compat
local pack = table.pack or function(...) return { n = select('#', ...), ... } end -- luacheck: compat

local cli = setmetatable({},{ __index = core })

function cli:parse(arguments, no_cleanup)
  if not no_cleanup then
    cli:cleanup()
  end

  -- `#` is undefined for a table with a nil hole (e.g. the `nil, err`
  -- returned on a parsing error), so use pack/unpack's explicit `n`
  -- instead of relying on the table's border to reconstruct the count.
  local out = pack(core.parse(self, arguments))

  return unpack(out, 1, out.n)
end

-- Clean up the entire module (unload the scripts) as it's expected to be
-- discarded after use.
function cli:cleanup()
  for k, v in pairs(package.loaded) do
    if (v == cli) or (k:match('cliargs')) then
      package.loaded[k] = nil
    end
  end

  cli = nil
end

cli.VERSION = "3.0.2"

return cli
