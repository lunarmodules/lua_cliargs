local cli = require('cliargs.core')()
local deprecated = require('cliargs.utils.deprecated')

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

-- finalize setup
cli._COPYRIGHT   = "Copyright (C) 2011-2015 Ahmad Amireh"
cli._LICENSE     = "The code is released under the MIT terms. Feel free to use it in both open and closed software as you please."
cli._DESCRIPTION = "Command-line argument parser for Lua."
cli._VERSION     = "cliargs 3.0-0"

-- backward compatibility
deprecated('add_arg', 'add_argument', cli)
deprecated('add_opt', 'add_option', cli)
deprecated('parse_args', 'parse', cli)

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