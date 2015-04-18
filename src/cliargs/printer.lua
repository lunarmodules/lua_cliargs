local wordwrap = require('cliargs.utils.wordwrap')
local MAX_COLS = 72
local _

local function get_max_label_length(cli)
  local maxsz = 0

  for _,table_name in ipairs({"required", "optional"}) do
    for _, entry in ipairs(cli[table_name]) do
      if #entry.key > maxsz then
        maxsz = #entry.key
      end
    end
  end

  return maxsz
end

-- Generate the USAGE heading message.
local function generate_usage(cli)
  local msg = "Usage: " .. tostring(cli.name)

  if #cli.optional > 0 then
    msg = msg .. " [OPTIONS]"
  end
  if #cli.required > 0 or cli.optargument.maxcount > 0 then
    msg = msg .. " [--]"
  end
  if #cli.required > 0 then
    for _,entry in ipairs(cli.required) do
      msg = msg .. " " .. entry.key
    end
  end
  if cli.optargument.maxcount == 1 then
    msg = msg .. " [" .. cli.optargument.key .. "]"
  elseif cli.optargument.maxcount == 2 then
    msg = msg .. " [" .. cli.optargument.key .. "-1 [" .. cli.optargument.key .. "-2]]"
  elseif cli.optargument.maxcount > 2 then
    msg = msg .. " [" .. cli.optargument.key .. "-1 [" .. cli.optargument.key .. "-2 [...]]]"
  end

  return msg
end

local function generate_help(cli)
  local msg = generate_usage(cli) .. "\n"
  local col1 = cli.colsz[1]
  local col2 = cli.colsz[2]

  if col1 == 0 then
    col1 = get_max_label_length(cli)
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

  if cli.required[1] then
    msg = msg .. "\nARGUMENTS: \n"
    for _,entry in ipairs(cli.required) do
      append(entry.key, entry.desc .. " (required)")
    end
  end

  if cli.optargument.maxcount > 0 then
    append(cli.optargument.key, cli.optargument.desc .. " (optional, default: " .. cli.optargument.default .. ")")
  end

  if #cli.optional > 0 then
    msg = msg .. "\nOPTIONS: \n"

    for _,entry in ipairs(cli.optional) do
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

return {
  generate_usage = generate_usage,
  generate_help = generate_help
}