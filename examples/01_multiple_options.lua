--[[
This example shows how to use multiple-value options that get appended into a
list.

Try this file with the following invocations;

  multiple_options.lua --help

  multiple_options.lua \
    -i http://www.google.com \
    -i http://www.yahoo.com \
    -j 2 \
    combined.html
--]]

local cli = require "cliargs"

cli:set_name("example.lua")

cli:splat("OUTPUT", "Path to where the combined HTML output should be saved.", "./a.html")

cli:option("-i URLs...", "A url to download. You can pass in as many as needed", {} --[[ this is the important bit! ]])
cli:option("-j THREADS", "Concurrency threshold; the higher the number, the more files will be downloaded in parallel.", "2")

-- Parses from _G['arg']
local args, err = cli:parse()

if not args and err then
  print(err)
  os.exit(1) -- something wrong happened and an error was printed
end

if #args.i > 0 then
  print("Source URLs:")

  for i, url in ipairs(args.i) do
    print("  " .. i .. ". " .. url)
  end

  print("Downloading ".. #args.i .. " files in " .. tonumber(args.j) .. " threads.")
  print("Output will be found at " .. args.OUTPUT)
else
  print("No source URLs provided, nothing to do!")
end
