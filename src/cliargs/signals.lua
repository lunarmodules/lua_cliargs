return {
  -- Returning this signal from a parse callback will cause the parser to
  -- restart its parsing routine.
  --
  -- This is useful in the cases where you may incur side-effects in callbacks
  -- that would change the outcome of the parse routine, like reading default
  -- values from a configuration file (at runtime.)
  --
  -- **CAREFUL** to install guards around the part that emits this signal,
  -- otherwise you will force the parser into an infinite loop!
  --
  -- Example:
  --
  --     local signals = require 'cliargs.signals'
  --     local already_did_my_stuff = false
  --
  --     cli:add_option('--config=FILE', '...', nil, function(_, path)
  --       -- do things that may affect the parse outcome and thus require a
  --       -- restart with the new state:
  --       if not already_did_my_stuff then
  --         already_did_my_stuff = true
  --
  --         return nil, signals.SIGNAL_RESTART
  --       end
  --     end)
  --
  SIGNAL_RESTART = '__signal_restart__'
}