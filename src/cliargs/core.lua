-- luacheck: ignore 212

local _
local disect = require('cliargs.utils.disect')
local disect_argument = require('cliargs.utils.disect_argument')
local lookup = require('cliargs.utils.lookup')
local shallow_copy = require('cliargs.utils.shallow_copy')
local create_printer = require('cliargs.printer')

local function is_callable(fn)
  return type(fn) == "function" or (getmetatable(fn) or {}).__call
end

local function validate_default_for_option(key, default)
  assert(
    type(default) == "string"
    or type(default) == "number"
    or default == nil
    or type(default) == "boolean"
    or type(default) == "table"
    ,
    "Default argument for '" .. key ..
    "' expected a string, a number, nil, or {}, got " .. type(default)
  )
end

local function validate_default_for_flag(key, default)
  assert(default == nil or type(default) == "boolean",
    "Default argument for '" .. key ..
    "' expected a boolean or nil, got " .. type(default)
  )
end

-- -------- --
-- CLI Main --
-- -------- --
return function()
  local cli = {}
  local required = {}
  local optional = {}
  local optargument = {maxcount = 0}
  local colsz = { 0, 0 } -- column width, help text. Set to 0 for auto detect
  local silent = false

  cli.name = ""
  cli.description = ""
  cli.printer = create_printer(function()
    return {
      name = cli.name,
      description = cli.description,
      required = required,
      optional = optional,
      optargument = optargument,
      colsz = colsz
    }
  end)

  --- @property {function} custom_error_handler
  ---
  --- A function to call when a parsing error has occured (at run-time).
  ---
  --- @param {string} msg
  ---        The error message.
  local custom_error_handler = nil

  local function on_error(msg)
    if custom_error_handler then
      return custom_error_handler(msg, { name = cli.name })
    end

    local full_msg = cli.name .. ": error: " .. msg .. '; re-run with --help for usage.'

    if not silent then
      cli.printer.print(full_msg)
    end

    return nil, full_msg
  end

  -- Used internally to add an option
  local function really_add_option(k, expanded_key, v, label, desc, default, callback)
    local flag = (v == nil) -- no value, so it's a flag
    local has_no_flag = flag and (expanded_key and expanded_key:find('^%[no%-]') ~= nil)
    local ek = has_no_flag and expanded_key:sub(6) or expanded_key

    -- guard against duplicates
    if lookup(k, ek, optional) then
      error("Duplicate option: " .. (k or ek) .. ", please rename one of them.")
    end

    if has_no_flag and lookup(nil, "no-"..ek, optional) then
      error("Duplicate option: " .. ("no-"..ek) .. ", please rename one of them.")
    end

    -- below description of full entry record, nils included for reference
    local entry = {
      key = k,
      expanded_key = ek,
      desc = desc,
      default = default,
      label = label,
      flag = flag,
      has_no_flag = has_no_flag,
      callback = callback,
      __display_key = ek or k
    }

    table.insert(optional, entry)
  end

  local function get_initial_values()
    local initial_values = {}

    for _, entry in ipairs(required) do
      initial_values[entry] = shallow_copy(entry.default)
    end

    for _, entry in ipairs(optional) do
      initial_values[entry] = shallow_copy(entry.default)
    end

    if optargument.key then
      if optargument.maxcount > 1 then
        initial_values[optargument] = {}
      else
        initial_values[optargument] = optargument.default
      end
    end

    return initial_values
  end

  -- ------------------------------------------------------------------------ --
  -- PUBLIC API
  -- ------------------------------------------------------------------------ --

  --- CONFIG

  --- Assigns the name of the program which will be used for logging.
  function cli:set_name(in_name)
    cli.name = in_name
  end

  --- Write down a brief, 1-liner description of what the program does.
  function cli:set_description(in_description)
    cli.description = in_description
  end

  --- Sets the amount of space allocated to the argument keys and descriptions
  --- in the help listing.
  ---
  --- The sizes are used for wrapping long argument keys and descriptions.
  ---
  --- @param {number} [key_cols=0]
  ---        The number of columns assigned to the argument keys, set to 0 to
  ---        auto detect.
  ---
  --- @param {number} [desc_cols=0]
  ---        The number of columns assigned to the argument descriptions, set to
  ---        0 to auto set the total width to 72.
  function cli:set_colsz(key_cols, desc_cols)
    colsz = { key_cols or colsz[1], desc_cols or colsz[2] }
  end

  function cli:set_silent(in_silent)
    silent = in_silent
  end

  function cli:set_error_handler(handler)
    custom_error_handler = handler
  end

  function cli:redefine_default(key, new_default)
    local entry = optargument.key == key and optargument or lookup(key, key, optional)

    assert(entry, "Unrecognized option with the key '" .. key .. "'")

    if entry.flag then
      validate_default_for_flag(key, new_default)
    else
      validate_default_for_option(key, new_default)
    end

    entry.default = shallow_copy(new_default)
  end

  --- Load default values from a table.
  function cli:load_defaults(config)
    for k, v in pairs(config) do
      self:redefine_default(k, v)
    end
  end

  --- Define a required argument.
  ---
  --- Required arguments have no special notation and are order-sensitive.
  ---
  --- @param {string} key
  ---
  ---        The argument identifier that will be displayed to the user and
  ---        be used to reference the run-time value.
  ---
  --- @param {string} desc
  ---
  ---        A description for this argument to display in usage help.
  ---
  --- @param {function} [callback]
  ---        Callback to invoke when this argument is parsed.
  ---
  --- @example
  ---
  --- The following will parse the argument (if specified) and set its value in
  --- `args["ROOT"]`:
  ---
  ---     cli:argument("ROOT", "path to where root scripts can be found")
  function cli:add_argument(key, desc, callback)
    assert(type(key) == "string" and type(desc) == "string",
      "Key and description are mandatory arguments (Strings)"
    )

    assert(callback == nil or is_callable(callback),
      "Callback argument must be a function"
    )

    if lookup(key, nil, required) then
      error("Duplicate argument: " .. key .. ", please rename one of them.")
    end

    table.insert(required, {
      key = key,
      desc = desc,
      callback = callback
    })
  end

  --- Defines an optional argument (or more than one).
  --- There can be only 1 optional argument, and it has to be the last one on the argumentlist.
  --- *Note:* the value will be stored in `args[@key]`. The value will be a 'string' if 'maxcount == 1',
  --- or a table if 'maxcount > 1'
  ---
  --- ### Parameters
  --- 1. **key**: the argument's "name" that will be displayed to the user
  --- 2. **desc**: a description of the argument
  --- 3. **default**: *optional*; specify a default value (the default is nil)
  --- 4. **maxcount**: *optional*; specify the maximum number of occurences allowed (default is 1)
  --- 5. **callback**: *optional*; specify a function to call when this argument is parsed (the default is nil)
  ---
  --- ### Usage example
  --- The following will parse the argument (if specified) and set its value in `args["root"]`:
  --- `cli:add_arg("root", "path to where root scripts can be found", "", 2)`
  --- The value returned will be a table with at least 1 entry and a maximum of 2 entries
  function cli:optarg(key, desc, default, maxcount, callback)
    assert(optargument.key == nil,
      "Only one splat argument may be defined."
    )

    assert(type(key) == "string" and type(desc) == "string",
      "Key and description are mandatory arguments (Strings)"
    )

    assert(type(default) == "string" or default == nil,
      "Default value must either be omitted or be a string"
    )

    maxcount = tonumber(maxcount or 1)

    assert(maxcount > 0 and maxcount < 1000,
      "Maxcount must be a number from 1 to 999"
    )

    assert(is_callable(callback) or callback == nil,
      "Callback argument: expected a function or nil"
    )

    optargument = {
      key = key,
      desc = desc,
      default = default,
      maxcount = maxcount,
      callback = callback
    }
  end

  --- Defines an optional argument.
  ---
  --- Optional arguments can use 3 different notations, and can accept a value.
  ---
  --- @param {string} key
  ---
  ---        The argument identifier. This can either be `-key`, or
  ---        `-key, --expanded-key`.
  ---        Values can be specified either by appending a space after the
  ---        identifier (e.g. `-key value` or `--expanded-key value`) or by
  ---        separating them with a `=` (e.g. `-key=value` or
  ---        `--expanded-key=value`).
  ---
  --- @param {string} desc
  ---
  ---        A description for the argument to be shown in --help.
  ---
  --- @param {bool} [default=nil]
  ---
  ---         A default value to use in case the option was not specified at
  ---         run-time (the default value is nil if you leave this blank.)
  ---
  --- @param {function} [callback]
  ---
  ---        A callback to invoke when this option is parsed.
  ---
  --- @example
  ---
  --- The following option will be stored in `args["i"]` and `args["input"]`
  --- with a default value of `file.txt`:
  ---
  ---     cli:option("-i, --input=FILE", "path to the input file", "file.txt")
  function cli:add_option(key, desc, default, callback)
    assert(type(key) == "string" and type(desc) == "string",
      "Key and description are mandatory arguments (Strings)"
    )

    assert(is_callable(callback) or callback == nil,
      "Callback argument: expected a function or nil"
    )

    local k, ek, v = disect(key)

    -- if there's no VALUE indicator anywhere, what they want really is a flag.
    -- e.g:
    --
    --     cli:option('-q, --quiet', '...')
    if v == nil then
      return self:add_flag(key, desc, default, callback)
    end

    validate_default_for_option(key, default)

    really_add_option(k, ek, v, key, desc, default, callback)
  end

  --- Define a flag argument (on/off). This is a convenience helper for cli.add_opt().
  --- See cli.add_opt() for more information.
  ---
  --- ### Parameters
  -- 1. **key**: the argument's key
  -- 2. **desc**: a description of the argument to be displayed in the help listing
  -- 3. **default**: *optional*; specify a default value (the default is nil)
  -- 4. **callback**: *optional*; specify a function to call when this flag is parsed (the default is nil)
  function cli:add_flag(key, desc, default, callback)
    if type(default) == "function" then
      callback = default
      default = nil
    end

    assert(type(key) == "string" and type(desc) == "string",
      "Key and description are mandatory arguments (Strings)"
    )

    validate_default_for_flag(key, default)

    local k, ek, v = disect(key)

    if v ~= nil then
      error("A flag type option cannot have a value set: " .. key)
    end

    really_add_option(k, ek, nil, key, desc, default, callback)
  end

  --- Parses the arguments found in #arg and returns a table with the populated values.
  --- (NOTE: after succesful parsing, the module will delete itself to free resources)
  --- *Aliases: `parse_args`*
  ---
  --- ### Parameters
  --- 1. **arguments**: set this to arg
  --- 2. **noprint**: set this flag to prevent any information (error or help info) from being printed
  --- 3. **dump**: set this flag to dump the parsed variables for debugging purposes, alternatively
  --- set the first option to --__DUMP__ (option with 2 trailing and leading underscores) to dump at runtime.
  ---
  --- ### Returns
  --- 1. a table containing the keys specified when the arguments were defined along with the parsed values,
  --- or nil + error message (--help option is considered an error and returns nil + help message)
  function cli:parse(arguments)
    local dump = nil

    assert(arguments == nil or type(arguments) == "table",
      "expected an argument table to be passed in, " ..
      "got something of type " .. type(arguments)
    )

    if not arguments then
      arguments = _G['arg'] or {}
    end

    -- clone args, don't mutate the original set:
    local args = shallow_copy(arguments)

    -- has --help or -h ? display the help listing and abort!
    for _, v in pairs(args) do
      if v == "--help" or v == "-h" then
        return nil, self:print_help()
      end
    end

    -- starts with --__DUMP__; set dump to true to dump the parsed arguments
    if dump == nil and args[1] and args[1] == "--__DUMP__" then
      dump = true
      table.remove(args, 1)  -- delete it to prevent further parsing
    end

    local values = get_initial_values()
    local argument_delimiter_found = false
    local function consume()
      return table.remove(args, 1)
    end

    local argument_cursor = 0

    while #args > 0 do
      local curr_opt = consume()
      local symbol, key, value, flag_negated = disect_argument(curr_opt)

      -- end-of-options indicator:
      if curr_opt == "--" then
        argument_delimiter_found = true

      -- an option:
      elseif not argument_delimiter_found and symbol then
        local entry = lookup(
          symbol == '-' and key or nil,
          symbol == '--' and key or nil,
          optional
        )

        if not key or not entry then
          local option_type = value and "option" or "flag"

          return on_error("unknown/bad " .. option_type .. ": " .. curr_opt)
        end

        if flag_negated and not entry.has_no_flag then
          return on_error("flag '" .. entry.__display_key .. "' may not be negated using --no-")
        end

        -- a flag and a value specified? that's an error
        if entry.flag and value then
          return on_error("flag --" .. key .. " does not take a value")
        elseif entry.flag then
          value = not flag_negated
        -- not a flag, value is in the next argument
        elseif not value then
          value = consume()
        end

        if type(entry.default) == 'table' then
          table.insert(values[entry], value)
        else
          values[entry] = value
        end

        if entry and entry.callback then
          local altkey = entry.key
          local status, err

          if key == entry.key then
            altkey = entry.expanded_key
          else
            key = entry.expanded_key
          end

          status, err = entry.callback(key, value, altkey, curr_opt)

          if status == nil and err then
            return on_error(err)
          end
        end

      -- an argument:
      else
        argument_cursor = argument_cursor + 1

        local curr_arg = required[argument_cursor]
        local entry = curr_arg

        -- splat arg
        if not curr_arg then
          if optargument.maxcount > 1 then
            table.insert(values[optargument], curr_opt)
          else
            values[optargument] = curr_opt
          end

          if optargument.callback then
            local status, err = optargument.callback(optargument.key, curr_opt)
            if status == nil and err then
              return on_error(err)
            end
          end
        -- regular arg
        else
          values[entry] = curr_opt

          if entry.callback then
            local status, err = entry.callback(entry.key, curr_opt)

            if status == nil and err then
              return on_error(err)
            end
          end
        end
      end
    end

    local arg_count = argument_cursor

    -- missing any required arguments, or too many?
    if arg_count < #required or arg_count > #required + optargument.maxcount then
      if optargument.maxcount > 0 then
        return on_error(
          "bad number of arguments: " ..
          #required .. "-" .. #required + optargument.maxcount ..
          " argument(s) must be specified, not " .. arg_count
        )
      else
        return on_error(
          "bad number of arguments: " ..
          #required .. " argument(s) must be specified, not " .. arg_count
        )
      end
    end

    -- if necessary set the defaults for the last optional argument here
    if optargument.maxcount > 1 and #values[optargument] == 0 then
      values[optargument] = { optargument.default }
    end

    -- populate the results table
    local results = {}

    if optargument.key then
      results[optargument.key] = values[optargument]
    end

    for _, entry in pairs(required) do
      results[entry.key] = values[entry]
    end

    for _, entry in pairs(optional) do
      if entry.key then
        results[entry.key] = values[entry]
      end

      if entry.expanded_key then
        results[entry.expanded_key] = values[entry]
      end
    end

    if dump then
      local msg = cli.printer.dump_internal_state(values)

      cli.printer.print(msg)

      return on_error("commandline dump created as requested per '--__DUMP__' option")
    end

    return results
  end

  --- Prints the USAGE message.
  ---
  --- @return {string}
  ---         The USAGE message.
  function cli:print_usage()
    local msg = cli.printer.generate_usage()

    if not silent then
      cli.printer.print(msg)
    end

    return msg
  end

  --- Prints the HELP information.
  ---
  --- @return {string}
  ---         The HELP message.
  function cli:print_help()
    local msg = ''

    msg = msg .. cli.printer.generate_usage() .. '\n'
    msg = msg .. cli.printer.generate_help()

    if not silent then
      cli.printer.print(msg)
    end

    return msg
  end

  return cli
end
