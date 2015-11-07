-- luacheck: ignore 212

local _
local disect = require('cliargs.utils.disect')
local disect_argument = require('cliargs.utils.disect_argument')
local lookup = require('cliargs.utils.lookup')
local shallow_copy = require('cliargs.utils.shallow_copy')
local create_printer = require('cliargs.printer')
local config_loader = require('cliargs.config_loader')

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
local create_core, create_command

create_core = function()
  --- @module
  ---
  --- The primary export you receive when you require the library. For example:
  ---
  ---     local cli = require 'cliargs'
  local cli = {}
  local required = {}
  local optional = {}
  local optargument = {maxcount = 0}
  local colsz = { 0, 0 } -- column width, help text. Set to 0 for auto detect
  local commands = {}

  cli.name = ""
  cli.description = ""

  cli.printer = create_printer(function()
    return {
      name = cli.name,
      description = cli.description,
      commands = commands,
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
      return custom_error_handler(msg)
    end

    return nil, msg
  end

  -- Used internally to add an option
  local function define_option(k, ek, v, label, desc, default, callback)
    local flag = (v == nil) -- no value, so it's a flag
    local negatable = flag and (ek and ek:find('^%[no%-]') ~= nil)

    if negatable then
      ek = ek:sub(6)
    end

    -- guard against duplicates
    if lookup(k, ek, optional) then
      error("Duplicate option: " .. (k or ek) .. ", please rename one of them.")
    end

    if negatable and lookup(nil, "no-"..ek, optional) then
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
      negatable = negatable,
      callback = callback
    }

    table.insert(optional, entry)
  end

  local function generate_results(cli_values)
    local results = {}
    local function collect(entry)
      local entry_values = {}
      local _

      for _, item in ipairs(cli_values) do
        if item.entry == entry then
          table.insert(entry_values, item.value)
        end
      end

      return entry_values
    end

    if optargument.key then
      local values = collect(optargument)

      if #values == 0 then
        values = { optargument.default }
      end

      if optargument.maxcount == 1 then
        results[optargument.key] = values[1]
      else
        results[optargument.key] = values
      end
    end

    for _, entry in pairs(required) do
      results[entry.key] = collect(entry)[1]
    end

    for _, entry in pairs(optional) do
      local values = collect(entry)
      local value

      if #values == 0 then
        value = entry.default
      else
        if type(entry.default) == 'table' then
          value = values
        else
          value = values[#values] -- use the last

          if value == '__CLIARGS_NULL__' then
            value = nil
          end
        end
      end

      if entry.key then
        results[entry.key] = value
      end

      if entry.expanded_key then
        results[entry.expanded_key] = value
      end
    end

    return results
  end

  -- ------------------------------------------------------------------------ --
  -- PUBLIC API
  -- ------------------------------------------------------------------------ --

  --- CONFIG

  --- Assigns the name of the program which will be used for logging.
  function cli:set_name(in_name)
    cli.name = in_name

    return self
  end

  --- Write down a brief, 1-liner description of what the program does.
  function cli:set_description(in_description)
    cli.description = in_description

    return self
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

  function cli:set_error_handler(handler)
    custom_error_handler = handler
  end

  function cli:redefine_default(key, new_default)
    local entry = optargument.key == key and optargument or lookup(key, key, optional)

    if not entry then
      return nil
    end

    if entry.flag then
      validate_default_for_flag(key, new_default)
    else
      validate_default_for_option(key, new_default)
    end

    entry.default = shallow_copy(new_default)

    return true
  end

  --- Load default values from a table.
  ---
  --- @param {table} config
  ---        Your new set of defaults. The keys could either point to the short
  ---        or expanded option keys, and their values are the new defaults.
  ---
  --- @param {boolean} [strict=false]
  ---        Turn this on to return nil and an error message if a key in the
  ---        config table could not be mapped to any CLI option.
  ---
  --- @return {true}
  ---         When the new defaults were loaded successfully, or strict was not
  ---         set.
  ---
  --- @return {union<nil, string>}
  ---         When strict was set and there was an error.
  function cli:load_defaults(config, strict)
    for k, v in pairs(config) do
      local success = self:redefine_default(k, v)

      if strict and not success then
        return nil, "Unrecognized option with the key '" .. k .. "'"
      end
    end

    return true
  end

  --- Read config values from a configuration file.
  ---
  --- @param {string} path
  ---        Absolute file path.
  ---
  --- @param {string} [format=nil]
  ---        The config file format, which has to be one of:
  ---        "lua", "json", "ini", or "yaml".
  ---        When this is left blank, we try to auto-detect the format from the
  ---        file extension.
  ---
  --- @param {boolean} [strict=false]
  ---        Forwarded to [#load_defaults](). See that method for the parameter
  ---        description.
  ---
  --- @return {true|union<nil, string>}
  ---         Returns true on successful load. Otherwise, nil and an error
  ---         message are returned instead.
  function cli:read_defaults(path, format)
    if not format then
      format = path:match('%.([^%.]+)$')
    end

    local loader = config_loader.FORMAT_LOADERS[format]

    if not loader then
      return nil, 'Unsupported file format "' .. format .. '"'
    end

    return config_loader[loader](path)
  end

  --- Define a required argument.
  ---
  ---
  --- Required arguments do not take a symbol like `-` or `--`, may not have a
  --- default value, and are parsed in the order they are defined.
  ---
  ---
  --- For example:
  ---
  --- ```lua
  --- cli:argument('INPUT', 'path to the input file')
  --- cli:argument('OUTPUT', 'path to the output file')
  --- ```
  ---
  --- At run-time, the arguments have to be specified using the following
  --- notation:
  ---
  --- ```bash
  --- $ ./script.lua ./main.c ./a.out
  --- ```
  ---
  --- If the user does not pass a value to _every_ argument, the parser will
  --- raise an error.
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
  function cli:argument(key, desc, callback)
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

    return self
  end

  --- Defines a "splat" (or catch-all) argument.
  ---
  --- This is a special kind of argument that may be specified 0 or more times,
  --- the values being appended to a list.
  ---
  --- For example, let's assume our program takes a single output file and works
  --- on multiple source files:
  ---
  --- ```lua
  --- cli:argument('OUTPUT', 'path to the output file')
  --- cli:splat('INPUTS', 'the sources to compile', nil, 10) -- up to 10 source files
  --- ```
  ---
  --- At run-time, it could be invoked as such:
  ---
  --- ```bash
  --- $ ./script.lua ./a.out file1.c file2.c main.c
  --- ```
  ---
  --- If you want to make the output optional, you could do something like this:
  ---
  --- ```lua
  --- cli:option('-o, --output=FILE', 'path to the output file', './a.out')
  --- cli:splat('INPUTS', 'the sources to compile', nil, 10)
  --- ```
  ---
  --- And now we may omit the output file path:
  ---
  --- ```bash
  --- $ ./script.lua file1.c file2.c main.c
  --- ```
  ---
  --- @param {string} key
  ---        The argument's "name" that will be displayed to the user.
  ---
  --- @param {string} desc
  ---        A description of the argument.
  ---
  --- @param {*} [default=nil]
  ---        A default value.
  ---
  --- @param {number} [maxcount=1]
  ---        The maximum number of occurences allowed.
  ---
  --- @param {function} [callback]
  ---        A function to call **everytime** a value for this argument is
  ---        parsed.
  ---
  function cli:splat(key, desc, default, maxcount, callback)
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

    return self
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
  function cli:option(key, desc, default, callback)
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
      return self:flag(key, desc, default, callback)
    end

    validate_default_for_option(key, default)

    define_option(k, ek, v, key, desc, default, callback)

    return self
  end

  --- Define an optional "flag" argument.
  ---
  --- Flags are a special subset of options that can either be `true` or `false`.
  ---
  --- For example:
  --- ```lua
  --- cli:flag('-q, --quiet', 'Suppress output.', true)
  --- ```
  ---
  --- At run-time:
  ---
  --- ```bash
  --- $ ./script.lua --quiet
  --- $ ./script.lua -q
  --- ```
  ---
  --- Passing a value to a flag raises an error:
  ---
  --- ```bash
  --- $ ./script.lua --quiet=foo
  --- $ echo $? # => 1
  --- ```
  ---
  --- Flags may be _negatable_ by prepending `[no-]` to their key:
  ---
  --- ```lua
  --- cli:flag('-c, --[no-]compress', 'whether to compress or not', true)
  --- ```
  ---
  --- Now the user gets to pass `--no-compress` if they want to skip
  --- compression, or either specify `--compress` explicitly or leave it
  --- unspecified to use compression.
  ---
  --- @param {string} key
  --- @param {string} desc
  --- @param {*} default
  --- @param {function} callback
  function cli:flag(key, desc, default, callback)
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

    define_option(k, ek, nil, key, desc, default, callback)

    return self
  end

  function cli:command(name, desc)
    local cmd = create_command(name)

    cmd:set_name(cli.name .. ' ' .. name)
    cmd:set_description(desc)

    table.insert(commands, cmd)

    return cmd
  end

  --- Parse the process arguments table.
  ---
  --- @param {table<string>} [arguments=_G.arg]
  ---        The list of arguments to parse. Defaults to the global `arg` table
  ---        which contains the arguments the process was started with.
  ---
  --- @return {table}
  ---         A table containing all the arguments, options, flags,
  ---         and splat arguments that were specified or had a default
  ---         (where applicable).
  ---
  --- @return {array<nil, string>}
  ---         If a parsing error has occured, note that the --help option is
  ---         also considered an error.
  function cli:parse(arguments)
    local dump = nil

    assert(arguments == nil or type(arguments) == "table",
      "expected an argument table to be passed in, " ..
      "got something of type " .. type(arguments)
    )

    if not arguments then
      arguments = _G.arg or {}
    end

    -- clone args, don't mutate the original set:
    local args = shallow_copy(arguments)

    -- starts with --__DUMP__; set dump to true to dump the parsed arguments
    if dump == nil and args[1] and args[1] == "--__DUMP__" then
      dump = true
      table.remove(args, 1)  -- delete it to prevent further parsing
    end

    local values = {}
    local argument_delimiter_found = false
    local function consume()
      return table.remove(args, 1)
    end

    -- fast-forward to locate a command if any and delegate to that
    for index, opt in ipairs(args) do
      local command

      for _, cmd in pairs(commands) do
        if cmd.__key__ == opt then
          command = cmd
          break
        end
      end

      if command then
        local command_args = shallow_copy(args)
        table.remove(command_args, index)

        if command.__action__ then
          local parsed_command_args, err = command:parse(command_args)

          if err then
            return on_error(err)
          end

          return command.__action__(parsed_command_args)
        elseif command.__file__ then
          local filename = command.__file__

          if type(filename) == 'function' then
            filename = filename()
          end

          local run_command_file = function()
            _G.arg = command_args

            local res, err = assert(loadfile(filename))()

            _G.arg = args

            return res, err
          end

          return run_command_file()
        end
      end
    end

    -- has --help or -h ? display the help listing and abort!
    for _, v in pairs(args) do
      if v == "--help" or v == "-h" then
        return nil, self:get_help_message()
      end
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

        if flag_negated and not entry.negatable then
          return on_error("flag '" .. curr_opt .. "' may not be negated using --no-")
        end

        -- a flag and a value specified? that's an error
        if entry.flag then
          if value then
            return on_error("flag " .. curr_opt .. " does not take a value")
          end

          value = not flag_negated
        -- an option:
        else
          -- the value might be in the next argument, e.g:
          --
          --     --compress lzma
          if not value then
            -- if the option contained a = and there's no value, it means they
            -- want to nullify an option's default value. eg:
            --
            --    --compress=
            if curr_opt:find('=') then
              value = '__CLIARGS_NULL__'
            else
              -- NOTE: this has the potential to be buggy and swallow the next
              -- entry as this entry's value even though that entry may be an
              -- actual argument/option
              --
              -- this would be a user error and there is no determinate way to
              -- figure it out because if there's no leading symbol (- or --)
              -- in that entry it can be an actual argument. :shrug:
              value = consume()

              if not value then
                return on_error("option " .. curr_opt .. " requires a value to be set")
              end
            end
          end
        end

        table.insert(values, { entry = entry, value = value })

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

      -- an argument or a splat argument:
      else
        argument_cursor = argument_cursor + 1

        local is_splat_value = argument_cursor > #required

        -- a splat argument:
        if is_splat_value then
          table.insert(values, { entry = optargument, value = curr_opt })

          if optargument.callback then
            local status, err = optargument.callback(optargument.key, curr_opt)
            if status == nil and err then
              return on_error(err)
            end
          end
        -- a regular argument:
        else
          local entry = required[argument_cursor]

          table.insert(values, { entry = entry, value = curr_opt })

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

    -- populate the results table
    local results = generate_results(values)

    if dump then
      return on_error(cli.printer.dump_internal_state(values))
    end

    return results
  end

  --- Prints the USAGE message.
  ---
  --- @return {string}
  ---         The USAGE message.
  function cli:print_usage()
    cli.printer.print(cli:get_usage_message())
  end

  function cli:get_usage_message()
    return cli.printer.generate_usage()
  end

  function cli:get_help_message()
    local msg = ''

    msg = msg .. cli.printer.generate_usage() .. '\n'
    msg = msg .. cli.printer.generate_help()

    return msg
  end

  --- Prints the HELP information.
  ---
  --- @return {string}
  ---         The HELP message.
  function cli:print_help()
    cli.printer.print(cli:get_help_message())
  end

  return cli
end

create_command = function(key)
  local cmd = create_core()

  cmd.__key__ = key

  function cmd:file(file_path)
    cmd.__file__ = file_path
    return cmd
  end

  function cmd:action(callback)
    cmd.__action__ = callback
    return cmd
  end

  return cmd
end

return create_core