
-- Used internally to lookup an entry using either its short or expanded keys
local function lookup(k, ek, argtable)
  local _
  local t = argtable

  for _, entry in ipairs(t) do
    if k  and entry.key == k then
      return entry
    end

    if ek and entry.expanded_key == ek then
      return entry
    end

    if entry.has_no_flag then
      if ek and ("no-"..entry.expanded_key) == ek then return entry end
    end
  end

  return nil
end

return lookup