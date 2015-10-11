local signals = require 'cliargs.signals'
local trim = require 'cliargs.utils.trim'
local already_injected = {}

local function inject(cli, config)
  if already_injected[cli] then
    return nil
  end

  already_injected[cli] = true

  for k, v in pairs(config) do
    cli:redefine_default(k, v)
  end

  return nil, signals.SIGNAL_RESTART
end

local function read_file(filepath)
  local f, err = io.open(filepath, "r")

  if not f then
    return nil, err
  end

  local contents = f:read('*all')

  f:close()

  return contents
end

return {
  from_object = inject,

  --- Inject configuration from a JSON file.
  ---
  --- Requires the "dkjson"[1] module to be present on the system. Get it with:
  ---
  ---     luarocks install dkjson
  ---
  --- [1] http://dkolf.de/src/dkjson-lua.fsl/home
  from_json = function(cli, filepath)
    local src, config, _, err
    local json = require 'dkjson'

    src, err = read_file(filepath)

    if not src and err then
      return nil, err
    end

    config, _, err = json.decode(src)

    if err then
      return nil, err
    end

    return inject(cli, config)
  end,

  --- Inject configuration from an INI file.
  ---
  --- Requires the "inifile"[1] module to be present on the system. Get it with:
  ---
  ---     luarocks install inifile
  ---
  --- The INI file must contain a group that lists the default values. For
  --- example:
  ---
  ---     [cli]
  ---     quiet = true
  ---     compress = lzma
  ---
  --- The routine will automatically cast boolean values ("true" and "false")
  --- into Lua booleans. You may opt out of this behavior by passing `false`
  --- to `no_cast`.
  ---
  --- [1] http://docs.bartbes.com/inifile
  from_ini = function(cli, filepath, group, no_cast)
    local inifile = require 'inifile'
    local config, err

    assert(type(group) == 'string',
      'You must provide an INI group to read from.'
    )

    config, err = inifile.parse(filepath)

    if not config and err then
      return nil, err
    end

    if not no_cast then
      for k, src_value in pairs(config[group]) do
        local v = trim(src_value)

        if v == 'true' then
          v = true
        elseif v == 'false' then
          v = false
        end

        config[group][k] = v
      end
    end

    return inject(cli, config[group])
  end,

  --- Inject configuration from a YAML file.
  ---
  --- Requires the "yaml"[1] module to be present on the system. Get it with:
  ---
  ---     luarocks install yaml
  ---
  --- [1] http://doc.lubyk.org/yaml.html
  from_yaml = function(cli, filepath)
    local src, config, _, err
    local yaml = require 'yaml'

    src, err = read_file(filepath)

    if not src and err then
      return nil, err
    end

    config, err = yaml.load(src)

    if not config and err then
      return nil, err
    end

    return inject(cli, config)
  end
}
