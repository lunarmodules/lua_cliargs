local split = require('cliargs.utils.split')

local function disect(key)
  -- characters allowed are a-z, A-Z, 0-9
  -- extended + values also allow; # @ _ + -
  local k, ek, v, _
  local dummy
  -- if there is no comma, between short and extended, add one
  _, _, dummy = key:find("^%-([%a%d]+)[%s]%-%-")
  if dummy then key = key:gsub("^%-[%a%d][%s]%-%-", "-"..dummy..", --", 1) end
  -- for a short key + value, replace space by "="
  _, _, dummy = key:find("^%-([%a%d]+)[%s]")
  if dummy then key = key:gsub("^%-([%a%d]+)[ ]", "-"..dummy.."=", 1) end
  -- if there is no "=", then append one
  if not key:find("=") then key = key .. "=" end
  -- get value
  _, _, v = key:find(".-%=(.+)")
  -- get key(s), remove spaces
  key = split(key, "=")[1]:gsub(" ", "")
  -- get short key & extended key
  _, _, k = key:find("^%-([^-][^%s,]*)")
  _, _, ek = key:find("%-%-(.+)$")
  if v == "" then v = nil end
  return k,ek,v
end

return disect