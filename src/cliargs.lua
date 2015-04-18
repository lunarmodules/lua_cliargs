local cli = require('cliargs.core')()

-- Clean up the entire module (unload the scripts) as it's expected to be
-- discarded after use.
function cli.cleanup()
  for k, v in pairs(package.loaded) do

    if (v == cli) or (k:match('cliargs')) then
      package.loaded[k] = nil
      break
    end
  end

  cli = nil
end

-- TODO: how to shadow cli:parse() ?
-- local parse = cli.parse
-- function cli:parse(arguments, noprint, dump, nocleanup)
--   local out = parse(arguments, noprint, dump)

--   if not nocleanup then
--     cli.cleanup()
--   end

--   return out
-- end

return cli