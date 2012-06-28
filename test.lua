local cli = require "cliargs"
cli:set_name("test.lua")
cli:add_argument("root", "path to where root scripts can be found")
cli:add_option("-o FILE", "path to the output file")
cli:add_option("-i, --input=FILE", "path to an input file", "input_path")
cli:add_flag("-v, --version", "prints the program's version and exits")

local args = cli:parse_args()
if not args then
  -- something wrong happened and an error was printed
  return
end

-- argument parsing was successful, arguments can be found in `args`
for k,item in pairs(args) do print(k .. " => " .. tostring(item)) end

-- checking for flags: is -v or --version set?
if args["v"] then
  return print("test.lua: version 0.0.0")
end

-- overridden keys:
print("Input file: " .. args["input_path"])
-- default keys:
print("Output file: " .. args["o"])

-- force display of help listing:
-- cli:print_help()