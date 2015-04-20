return function(func_name, new_name, target)
  local msg = (
    "cli#" .. func_name .. " is now deprecated and will be removed in " ..
    "a future version."
  )

  if new_name then
    msg = msg .. " Use cli#" .. new_name .. " instead."
  end

  target[func_name] = function(...)
    print(msg)

    if new_name then
      return target[new_name](...)
    else
      return target[func_name](...)
    end
  end
end