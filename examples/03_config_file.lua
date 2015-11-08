local cli = require 'cliargs'
local tablex = require 'pl.tablex' -- we'll need this for merging tables

cli:option('--config=FILEPATH', 'path to a config file', '.programrc')
cli:flag('--quiet', 'Do not output anything to STDOUT', false)

-- This example shows how to read default values from a base configuration file
-- and optionally, if the user passes in a custom config file using --config
-- we merge those with the parsed ones.

local function load_config_file(file_path)
  local config = {}
  local success = pcall(function()
    config = loadfile(file_path)()
  end)

  if success then
    return config
  end
end

-- first, let's load from a ".programrc" file in the current-working directory
-- if it exists and tell cliargs to use the defaults specified in that file:
local base_config = load_config_file('.programrc')

if base_config then
  cli:load_defaults(base_config)
end

-- now we parse the options like usual:
local args, err = cli:parse()

if not args and err then
  print(err)
  os.exit(1)
end

-- finally, let's check if the user passed in a config file using --config:
if args.config then
  local custom_config = load_config_file(args.config)

  if custom_config then
    -- We merge the user defaults with the run-time ones. Note that run-time
    -- arguments should always have precedence over config defined in files.
    args = tablex.merge({}, custom_config, args, true)
  end
end

-- args is now ready for use:
-- args.quiet will be whatever was set in the following priority:
--
-- 1. --quiet or --no-quiet on the CLI
-- 2. ["quiet"] in the user config file if --config was present
-- 3. ["quiet"] in the base config file (.programrc) if it existed
print(args.quiet)
