local cli = require('cliargs')
local config_injector = require('cliargs.config_injector')

-- The config injector supports loading runtime-config from different sources,
-- like a JSON file, a YAML file, or an INI file.
--
-- You can also define your own loading routine, of course. See below.

-- load options from a JSON file:
local function inject_config_from_json(_, filepath)
  return config_injector.from_json(cli, filepath)
end

-- load options from a YAML file:
local function inject_config_from_yaml(_, filepath)
  return config_injector.from_yaml(cli, filepath)
end

-- load options from an INI file:
local function inject_config_from_ini(_, filepath)
  return config_injector.from_ini(cli, filepath)
end

local function inject_config_from_custom_source(_, filepath)
  -- do what you need to do to get the config object
  -- then call the injector's "from_object" routine:
  local runtime_config = {}

  return config_injector.from_object(cli, runtime_config)
end

cli:add_option(
  '--config=FILEPATH',
  'path to a config file',
  '.programrc',
  inject_config_from_json
)
