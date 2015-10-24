local wordwrap = require('cliargs.utils.wordwrap')
local MAX_COLS = 72
local _

local function create_printer(get_parser_state)
  local printer = {}
  local function print(msg)
    return printer.print(msg)
  end

  function printer.print(msg)
    return _G.print(msg)
  end

  local function get_max_label_length()
    local maxsz = 0
    local state = get_parser_state()

    for _,table_name in ipairs({"required", "optional"}) do
      for _, entry in ipairs(state[table_name]) do
        local key = entry.label or entry.key

        if #key > maxsz then
          maxsz = #key
        end
      end
    end

    if state.optargument.key and #state.optargument.key > maxsz then
      maxsz = #state.optargument.key
    end

    return maxsz
  end

  -- Generate the USAGE heading message.
  function printer.generate_usage()
    local state = get_parser_state()
    local msg = "Usage:"

    if #state.name > 0 then
      msg = msg .. ' ' .. tostring(state.name)
    end

    if #state.optional > 0 then
      msg = msg .. " [OPTIONS]"
    end
    if #state.required > 0 or state.optargument.maxcount > 0 then
      msg = msg .. " [--]"
    end
    if #state.required > 0 then
      for _,entry in ipairs(state.required) do
        msg = msg .. " " .. entry.key
      end
    end
    if state.optargument.maxcount == 1 then
      msg = msg .. " [" .. state.optargument.key .. "]"
    elseif state.optargument.maxcount == 2 then
      msg = msg .. " [" .. state.optargument.key .. "-1 [" .. state.optargument.key .. "-2]]"
    elseif state.optargument.maxcount > 2 then
      msg = msg .. " [" .. state.optargument.key .. "-1 [" .. state.optargument.key .. "-2 [...]]]"
    end

    return msg
  end

  function printer.generate_help()
    local msg = ''
    local state = get_parser_state()
    local col1 = state.colsz[1]
    local col2 = state.colsz[2]

    local function append(label, desc)
      label = "  " .. label .. string.rep(" ", col1 - (#label + 2))
      desc = wordwrap(desc, col2)   -- word-wrap
      desc = desc:gsub("\n", "\n" .. string.rep(" ", col1)) -- add padding

      msg = msg .. label .. desc .. "\n"
    end

    if col1 == 0 then
      col1 = get_max_label_length(state)
    end

    -- add margins
    col1 = col1 + 3

    if col2 == 0 then
      col2 = MAX_COLS - col1
    end

    if col2 < 10 then
      col2 = 10
    end

    if state.required[1] or state.optargument.key then
      msg = msg .. "\nARGUMENTS: \n"

      for _,entry in ipairs(state.required) do
        append(entry.key, entry.desc .. " (required)")
      end
    end

    if state.optargument.key then
      local optarg_desc = ' ' .. state.optargument.desc

      if state.optargument.default then
        optarg_desc = optarg_desc .. " (optional, default: " .. state.optargument.default .. ")"
      else
        optarg_desc = optarg_desc .. " (optional)"
      end

      append(state.optargument.key, optarg_desc)
    end

    if #state.optional > 0 then
      msg = msg .. "\nOPTIONS: \n"

      for _,entry in ipairs(state.optional) do
        local desc = entry.desc
        if not entry.flag and entry.default and #tostring(entry.default) > 0 then
          local readable_default = type(entry.default) == "table" and "[]" or tostring(entry.default)
          desc = desc .. " (default: " .. readable_default .. ")"
        elseif entry.flag and entry.negatable then
          local readable_default = entry.default and 'on' or 'off'
          desc = desc .. " (default: " .. readable_default .. ")"
        end
        append(entry.label, desc)
      end
    end

    return msg
  end

  function printer.dump_internal_state(values)
    local state = get_parser_state()
    local maxlabel = get_max_label_length()
    local msg = ''

    local function print(fragment)
      msg = msg .. fragment .. '\n'
    end

    print("\n======= Provided command line =============")
    print("\nNumber of arguments: ", #arg)

    for i,v in ipairs(arg) do -- use gloabl 'arg' not the modified local 'args'
      print(string.format("%3i = '%s'", i, v))
    end

    print("\n======= Parsed command line ===============")
    if #state.required > 0 then print("\nArguments:") end
    for _, entry in ipairs(state.required) do
      print(
        "  " ..
        entry.key .. string.rep(" ", maxlabel + 2 - #entry.key) ..
        " => '" ..
        tostring(values[entry]) ..
        "'"
      )
    end

    if state.optargument.maxcount > 0 then
      print(
        "\nOptional arguments:" ..
        state.optargument.key ..
        "; allowed are " ..
        tostring(state.optargument.maxcount) ..
        " arguments"
      )

      if state.optargument.maxcount == 1 then
          print(
            "  " .. state.optargument.key ..
            string.rep(" ", maxlabel + 2 - #state.optargument.key) ..
            " => '" ..
            state.optargument.key ..
            "'"
          )
      else
        for i = 1, state.optargument.maxcount do
          if values[state.optargument] and values[state.optargument][i] then
            print(
              "  " .. tostring(i) ..
              string.rep(" ", maxlabel + 2 - #tostring(i)) ..
              " => '" ..
              tostring(values[state.optargument][i]) ..
              "'"
            )
          end
        end
      end
    end

    if #state.optional > 0 then print("\nOptional parameters:") end
    local doubles = {}
    for _, entry in pairs(state.optional) do
      if not doubles[entry] then
        local value = values[entry]

        if type(value) == "string" then
          value = "'"..value.."'"
        else
          value = tostring(value) .." (" .. type(value) .. ")"
        end

        print("  " .. entry.label .. string.rep(" ", maxlabel + 2 - #entry.label) .. " => " .. value)

        doubles[entry] = entry
      end
    end

    print("\n===========================================\n\n")

    return msg
  end

  return printer
end

return create_printer