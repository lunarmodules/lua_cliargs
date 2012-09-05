local cli = {}

-- ------- --
-- Helpers --
-- ------- --
local expand = function(str, size, fill)
  if not fill then fill = ' ' end

  local out = str

  for i=0,size - #str do
    out = out .. fill
  end

  return out
end

local split = function(str, pat)
  local t = {}
  local fpat = "(.-)" .. pat
  local last_end = 1
  local s, e, cap = str:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
  table.insert(t,cap)
    end
    last_end = e+1
    s, e, cap = str:find(fpat, last_end)
  end
  if last_end <= #str then
    cap = str:sub(last_end)
    table.insert(t, cap)
  end
  return t
end

local join = function(t, delim)
  out = ""
  i = 0
  for _,item in pairs(t) do
    out = item .. delim
  end
  out = out:sub(0, #out - #delim)
  return out
end

local delimit = function(str, size, pad)
  if not pad then pad = 0 end

  local out = ""
  local words = split(str, ' ')

  local offset = 0
  for word_idx,word in pairs(words) do
    out = out .. word .. ' '
    offset = offset + #word
    if offset > size and word_idx ~= #words then
      out = out .. '\n'
      for i=0,pad do out = out .. ' '; end
      offset = 0
    end
  end

  return out
end

-- -------- --
-- CLI Main --
-- -------- --

--- Creates a new instance of the CLI arguments parser and consumes `arg`.
---
--- **Note**: you don't need to invoke this directly as it is automatically
--- done when you `require("cli")`.
---
--- ### Parameters
--- 1. **name**: The name of the application, used in usage and help listings
function cli:new(name)
  local o = {}
  setmetatable(o, { __index = self })
  self.__index = self

  o.name = name
  o.required = required_args or {}
  o.optional = optional_args or {}
  o.args = arg

  o.colsz = { 20, 45 }

  return o
end

function cli:error(msg)
  print(self.name .. ": error: " .. msg .. '; re-run with --help for usage.')
  return false
end

--- Assigns the name of the program which will be used for logging.
function cli:set_name(name)
  self.name = name
end

--- Defines a required argument.
--- Required arguments have no special notation and are order-sensitive.
--- *Note:* if `@ref` is omitted, the value will be stored in `args[@key]`.
--- *Aliases: `add_argument`*
---
--- ### Parameters
--- 1. **key**: the argument's "name" that will be displayed to the user
--- 1. **desc**: a description of the argument
--- 1. **ref**: optional; the table key that will be used to hold the value of this argument
---
--- ### Usage example
--- The following will parse the argument (if specified) and set its value in `args["root_path"]`:
--- `cli:add_arg("root", "path to where root scripts can be found", "root_path")`
function cli:add_arg(key, desc, ref)
  if not ref then ref = key end
  table.insert(self.required, { key = key, desc = desc, ref = ref })
end

--- Defines an optional argument.
--- Optional arguments can use 3 different notations, and can accept a value.
--- *Aliases: `add_option`*
---
--- ### Parameters
--- 1. **key**: the argument identifier, can be either `-key`, or `-key, --expanded-key`:
--- if the first notation is used then a value can be defined after a space (`'-key VALUE'`),
--- if the 2nd notation is used then a value can be defined after an `=` (`'key, --expanded-key=VALUE'`).
--- 1. **desc**: a description for the argument to be shown in --help
--- 1. **ref**: *optional*; override where the value will be stored, @see cli:add_arg
--- 1. **default**: *optional*; specify a default value (the default is "")
---
--- ### Usage example
--- The following option will be stored in `args["i"]` with a default value of `my_file.txt`:
--- `cli:add_option("-i, --input=FILE", "path to the input file", nil, "my_file.txt")`
function cli:add_opt(key, desc, ref, default)
  if not ref then
    if key:find('%-%-') == 1 then
      ref = key:gsub("(%-%-)", ""):gsub("(=.*)", "")
    else
      ref = string.gsub(key, '[%W]', ''):sub(0,1)
    end
  end

  local entry = {
    key = key,
    expanded_key = "",
    ref = ref,
    value = "",
    desc = desc,
    default = default == nil and "" or default
    -- default = default
  }

  -- parameterize the key if needed, possible variations:
  -- 1. -key
  -- 2. -key VALUE
  -- 3. -key, --expanded
  -- 4. -key, --expanded=VALUE

  -- -a, --argument[=VALUE] was passed
  if key:find(',') then
    local k,ek = unpack( split(key, ',') )
            ek = ek:gsub(' ', '')
    if ek:find('=') then
      ek,v = unpack( split(ek,'=') )
         v = v:gsub(' ', '')

      entry.value = v
    end

    entry.key = k
    entry.expanded_key = ek
  -- --argument[=VALUE] was passed
  elseif key:find('%-%-') == 1 then
    if key:find('=') then
      k,v = unpack( split(key,'=') )
        v = v:gsub(' ', '')

      entry.value = v
      key = k
    end
    entry.key = ""-- key
    entry.expanded_key = key
  -- -a[ VALUE] was passed
  elseif key:find(' ') then
    local k,v = unpack( split(key, ' ') )
          k = k:gsub(' ', '')
          v = v:gsub(' ', '')

    entry.key, entry.value = k, v
  end

  table.insert(self.optional, entry)
end

--- Define a flag argument (on/off). This is a convenience helper for cli.add_opt().
--- See cli.add_opt() for more information.
---
--- ### Parameters
-- 1. **key**: the argument's key
-- 1. **desc**: a description of the argument to be displayed in the help listing
-- 1. **ref**: optionally override where the key which will hold the value
function cli:add_flag(key, desc, ref)
  return self:add_opt(key, desc, ref, false)
end

function cli:locate_entry(key)
  -- strip the leading -- from the key if it's an expanded one
  if key:find('%-%-') == 1 and key:find('=') then
    key = split(key, '=')[1]
  end

  for _,entry in ipairs(self.optional) do
    if entry.key == key then
      return entry,false
    elseif entry.expanded_key == key then
      return entry,true
    end
  end

  return nil, nil
end

--- Parses the arguments found in #arg and returns a table with the populated values.
--- ### Returns
--- 1. a table containing the keys specified when the arguments were defined along with the parsed values.
function cli:parse_args(dump)

  -- starts with --help? display the help listing and abort!
  if self.args[1] and (self.args[1] == "--help" or self.args[1] == "-h") then
    return self:print_help()
  end

  -- missing any required arguments?
  if #self.args < #self.required then
    self:error("missing arguments, at least " .. #self.required .. " argument(s) must be specified")
    self:print_usage()
    return false
  end

  -- print("Received " .. #self.args .. " arguments, required: " .. #self.required)

  local args = {} -- returned set

  -- set up defaults
  for _,entry in ipairs(self.optional) do
    args[ entry.ref ] = entry.default
  end

  local req_idx = 1

  for arg_idx, arg in ipairs(arg) do
    repeat
      if skip then
        skip = false
        break
      end

      local entry, uses_expanded = self:locate_entry(arg)

      -- if it's an optional argument (starts with '-'), it must be listed
      if arg:find('-') == 1 and not entry then
        return self:error("unknown option " .. arg)
      end

      -- it's a required argument
      if not entry then
        -- or it's one too many arguments
        if not self.required[req_idx] then
          return self:error("too many arguments! Can't map '" .. arg .. "'")
        end

        args[ self.required[req_idx].ref ] = arg
        req_idx = req_idx + 1

      -- it's an optional argument, determine its type and which notation it uses
      else
        local arg_val = nil

        -- it's a flag, using either -f --f notations
        if #entry.value == 0 then
          arg_val = true

        -- an option using the -option VALUE notation:
        elseif not uses_expanded then
          if #self.args == arg_idx then
            return self:error("missing argument value in '" .. entry.key .. " " .. entry.value .. "'")
          else
            arg_val = self.args[arg_idx+1]
            skip = true
          end

        -- an option using the --option=VALUE notation
        else
          if not arg:find('=') then
            return
              self:error("missing argument value in '" .. entry.expanded_key ..
              "', value must be specified using: " .. entry.expanded_key .. "=" .. entry.value)
          end

          -- local v = split(arg, '=')
          arg_val = arg:sub(#entry.expanded_key+2,#arg)
          -- for i=1,#v do
            -- arg_val = v[i] .. "="
          -- end
          -- table.remove(arg_val, 1)
          -- arg_val = join(arg_val, '=')
          -- print('joined value: ' .. arg_val)
        end

        args[ entry.ref ] = arg_val
      end

    until true
  end

  if req_idx - 1 < #self.required then
    return self:error("missing required arguments")
  end

  if dump then
    for k,v in pairs(args) do print("  " .. k .. " => " .. tostring(v)) end
  end

  return args
end

function cli:print_usage()
  -- print the USAGE heading
  local msg = "Usage: " .. self.name
  if self.optional and #self.optional > 0 then
    msg = msg .. " [OPTIONS] "
  end
  if self.required and #self.required > 0 then
    for _,entry in ipairs(self.required) do
      msg = msg .. " " .. entry.key .. " "
    end
  end

  print(msg)
end


function cli:print_help()
  self:print_usage()

  local msg = ""

  if self.required and #self.required > 0 then
    msg = msg .. "\nRequired arguments: \n"

    for _,entry in ipairs(self.required) do
      local arg_key, arg_desc, arg_name =
            entry.key, entry.desc, entry.ref

      msg = msg ..
            "  " .. expand(arg_key, self.colsz[1]) ..
            delimit(arg_desc, self.colsz[2], self.colsz[1] + 2 --[[ margin ]]) .. '\n'
    end
  end

  if self.optional and #self.optional > 0 then
    msg = msg .. "\nOptional arguments: \n"

    for _,entry in ipairs(self.optional) do
      local arg_key, arg_desc, arg_name, arg_default, arg_ph =
            entry.key, entry.desc, entry.ref, entry.default, entry.value

      if arg_default then
        arg_desc = arg_desc .. " (default: " .. arg_default .. ")"
      end

      local separator = " "
      if #entry.expanded_key > 0 then
        arg_key = (#arg_key > 0 and arg_key .. ", " or "") .. entry.expanded_key
        separator = #entry.value > 0 and "=" or ""
      end
      if arg_ph then
        arg_key = arg_key .. separator .. arg_ph
      end

      msg = msg .. "  " ..
        expand(arg_key, self.colsz[1]) ..
        delimit(arg_desc, self.colsz[2], self.colsz[1] + 2 --[[ margin ]]) .. '\n'
    end
  end

  print(msg)
end

--- Sets the amount of space allocated to the argument keys and descriptions in the help listing.
--- The sizes are used for wrapping long argument keys and descriptions.
--- ### Parameters
--- 1. **key_cols**: the number of columns assigned to the argument keys (default: 20)
--- 1. **desc_cols**: the number of columns assigned to the argument descriptions (default: 45)
function cli:set_colsz(key_cols, desc_cols)
  self.colsz = { key_cols or self.colsz[1], desc_cols or self.colsz[2] }
end

cli.version = "1.1-0"

-- aliases
cli.add_argument = cli.add_arg
cli.add_option = cli.add_opt

return cli:new("")
