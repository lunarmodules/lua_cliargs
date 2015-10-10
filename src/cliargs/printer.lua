local wordwrap = require('cliargs.utils.wordwrap')
local MAX_COLS = 72
local _

local function get_max_label_length(state)
  local maxsz = 0

  for _,table_name in ipairs({"required", "optional"}) do
    for _, entry in ipairs(state[table_name]) do
      local key = entry.label or entry.key

      if #key > maxsz then
        maxsz = #key
      end
    end
  end

  return maxsz
end

-- Generate the USAGE heading message.
local function generate_usage(state)
  local msg = "Usage: " .. tostring(state.name)

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

local function generate_help(state, colsz)
  local msg = generate_usage(state) .. "\n"
  local col1 = colsz[1]
  local col2 = colsz[2]

  if col1 == 0 then
    col1 = get_max_label_length(state)
  end

  -- add margins
  col1 = col1 + 3

  if col2 == 0 then
    col2 = MAX_COLS - col1
  end

  if col2 <10 then col2 = 10 end

  local append = function(label, desc)
      label = "  " .. label .. string.rep(" ", col1 - (#label + 2))
      desc = wordwrap(desc, col2)   -- word-wrap
      desc = desc:gsub("\n", "\n" .. string.rep(" ", col1)) -- add padding

      msg = msg .. label .. desc .. "\n"
  end

  if state.required[1] then
    msg = msg .. "\nARGUMENTS: \n"
    for _,entry in ipairs(state.required) do
      append(entry.key, entry.desc .. " (required)")
    end
  end

  if state.optargument.maxcount > 0 then
    append(state.optargument.key, state.optargument.desc .. " (optional, default: " .. state.optargument.default .. ")")
  end

  if #state.optional > 0 then
    msg = msg .. "\nOPTIONS: \n"

    for _,entry in ipairs(state.optional) do
      local desc = entry.desc
      if not entry.flag and entry.default and #tostring(entry.default) > 0 then
        local readable_default = type(entry.default) == "table" and "[]" or tostring(entry.default)
        desc = desc .. " (default: " .. readable_default .. ")"
      elseif entry.flag and entry.has_no_flag then
        local readable_default = entry.default and 'on' or 'off'
        desc = desc .. " (default: " .. readable_default .. ")"
      end
      append(entry.label, desc)
    end
  end

  return msg
end

local function dump_internal_state(state)
  local maxlabel = get_max_label_length(state)

  print("\n======= Provided command line =============")
  print("\nNumber of arguments: ", #arg)

  for i,v in ipairs(arg) do -- use gloabl 'arg' not the modified local 'args'
    print(string.format("%3i = '%s'", i, v))
  end

  print("\n======= Parsed command line ===============")
  if #state.required > 0 then print("\nArguments:") end
  for _,v in ipairs(state.required) do
    print("  " .. v.key .. string.rep(" ", maxlabel + 2 - #v.key) .. " => '" .. v.value .. "'")
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
        if state.optargument.value[i] then
          print(
            "  " .. tostring(i) ..
            string.rep(" ", maxlabel + 2 - #tostring(i)) ..
            " => '" ..
            tostring(state.optargument.value[i]) ..
            "'"
          )
        end
      end
    end
  end

  if #state.optional > 0 then print("\nOptional parameters:") end
  local doubles = {}
  for _, v in pairs(state.optional) do
    if not doubles[v] then
      local m = v.value
      if type(m) == "string" then
        m = "'"..m.."'"
      else
        m = tostring(m) .." (" .. type(m) .. ")"
      end
      print("  " .. v.label .. string.rep(" ", maxlabel + 2 - #v.label) .. " => " .. m)
      doubles[v] = v
    end
  end

  print("\n===========================================\n\n")
end

return {
  generate_usage = generate_usage,
  generate_help = generate_help,
  dump_internal_state = dump_internal_state
}