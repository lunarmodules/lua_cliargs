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
function cli:new(name, required_args, optional_args)
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

function cli:set_name(name)
  self.name = name
end
function cli:add_arg(key, desc, ref)
  table.insert(self.required, { key = key, desc = desc, ref = ref })
end

function table.dump(t, indent_level)
  print("Dumping table " .. tostring(t) .. " which has " .. #t .. " elements")
  indent = ""; for i = 0, indent_level do indent = "\t" .. indent end
  for k,v in pairs(t) do
    print(indent .. tostring(k) .. " => " .. tostring(v))
  end
end

-- opts: { expanded_key = "--output", value_type="FILE", default="./file.txt" }
function cli:add_flag(key, desc, ref)
  return self:add_opt(key, desc, ref, { default = false })
end
function cli:add_opt(key, desc, ref, opts)
  -- is a placeholder value specified? (ie: in '-o FILE', capture the FILE part)
  -- local name_val = split(name, ' ')
  -- local name,val = name, ""
  -- if #name_val > 1 then
    -- name, val = name_val[1], name_val[#name_val]
  -- end

  opts = opts or {}
  for _,default_opt in pairs({ "expanded_key", "value", "default" }) do
    if opts[default_opt] == nil then
      opts[default_opt] = ""
    end
  end

  if not ref then
    ref = key:gsub('[%W]', ''):sub(0,1)
  end

  local entry = { 
    key = key,
    expanded_key = opts.expanded_key,
    ref = ref,
    value = opts.value,
    desc = desc,
    default = opts.default
  }

  -- parameterize the key if needed, possible variations:
  -- 1. -key
  -- 2. -key VALUE
  -- 3. -key, --expanded
  -- 4. -key, --expanded=VALUE

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
  end

  table.insert(self.optional, entry)

  table.dump(self.optional[#self.optional], 1)
end

function cli:locate_entry(key)
  if key:find('--') == 1 and key:find('=') then
    key = split(key, '=')[1]
    -- print("stripped key: " .. key)
  end

  for _,entry in ipairs(self.optional) do
    if entry.key == key then return entry,false
    elseif entry.expanded_key == key then return entry,true end
  end

  return nil, nil
end

function cli:parse_args()

  -- missing any required arguments?
  if #self.args < #self.required then
    self:error("missing arguments, at least " .. #self.required .. " argument(s) must be specified")
    self:print_usage()
    return false
  end

  -- starts with --help? display the help listing and abort!
  if self.args[1] and self.args[1] == "--help" then
    return self:print_help()
  end

  -- print("Received " .. #self.args .. " arguments, required: " .. #self.required)

  local args = {} -- returned set

  -- set up defaults
  -- for _,entry in ipairs(self.required) do
  --   table.dump(entry)
  --   -- args[ entry[3] ] = entry[4] or ""
  --   args[ entry.ref ] = entry.default
  -- end
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

          arg_val = split(arg, '=')[2] or ""
        end

        args[ entry.ref ] = arg_val
      end

    until true
  end

  if req_idx - 1 < #self.required then
    return self:error("missing required arguments")
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
      local arg_key, arg_desc, arg_name =
            entry.key, entry.desc, entry.ref

      msg = msg .. " " .. arg_key .. " "
    end
  end

  print(msg)
end


function cli:print_help()
  self:print_usage()

  local keysz = 20
  local msg = ""

  if self.required and #self.required > 0 then
    msg = msg .. "\nRequired arguments: \n"

    for _,entry in ipairs(self.required) do
      local arg_key, arg_desc, arg_name =
            entry.key, entry.desc, entry.ref

      msg = msg ..
            "  " .. expand(arg_key, keysz) ..
            arg_desc .. "\n"
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
        arg_key = arg_key .. ", " .. entry.expanded_key
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

function cli:set_helpsz(rows, cols)
  self.colsz = { rows or self.colsz[1], cols or self.colsz[2] }
end
-- aliases
cli.add_argument = cli.add_arg
cli.add_option = cli.add_opt

return cli:new("")
