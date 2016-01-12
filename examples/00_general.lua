--[[

Try this file with the following commands lines;
  example.lua --help
  example.lua -o myfile -d --compress=gzip inputfile
  example.lua --__DUMP__ -o myfile -d --compress=gzip inputfile

--]]

local cli = require "cliargs"

-- this is called when the flag -v or --version is set
local function print_version()
  print("cli_example.lua: version 1.2.1")
  print("lua_cliargs: version " .. cli.VERSION)
  os.exit(0)
end

cli:set_name("cli_example.lua")

-- Required arguments:
cli:argument("OUTPUT", "path to the output file")

-- Optional (repetitive) arguments
-- only the last argument can be optional. Being set to maximum 3 optionals.
cli:splat("INPUTS", "the source files to read from", "/tmp/foo", 3)

-- Optional parameters:
cli:option("-c, --compress=FILTER", "the filter to use for compressing output: gzip, lzma, bzip2, or none", "gzip")
-- cli:option("-o FILE", "path to output file", "/dev/stdout")

-- Flags: a flag is a boolean option. Defaults to false
-- A flag with short-key notation only
cli:flag("-d", "script will run in DEBUG mode")
-- A flag with both the short-key and --expanded-key notations, and callback function
cli:flag("-v, --version", "prints the program's version and exits", print_version)
-- A flag with --expanded-key notation only
cli:flag("--verbose", "the script output will be very verbose")
-- A flag that can be negated using --no- as a prefix, but you'll still have
-- to access its value without that prefix. See below for an example.
cli:flag('--[no-]ice-cream', 'ice cream, or not', true)

-- Parses from _G['arg']
local args, err = cli:parse(arg)

if not args and err then
  -- something wrong happened and an error was printed
  print(string.format('%s: %s; re-run with help for usage', cli.name, err))
  os.exit(1)
elseif not args['ice-cream'] then
  print('kernel panic: NO ICE CREAM?!11')
  os.exit(1000)
end

-- argument parsing was successful, arguments can be found in `args`
-- upon successful parsing cliargs will delete itslef to free resources
-- for k,item in pairs(args) do print(k .. " => " .. tostring(item)) end

print("Output file: " .. args["OUTPUT"])

print("Input files:")

for i, out in ipairs(args.INPUTS) do
  print("  " .. i .. ". " .. out)
end

print(args.c)
if not args['c'] or args['c'] == 'none' then
  print("Won't be compressing")
else
  print("Compressing using " .. args['c'])
end

if args['ice-cream'] then
  print('And, one ice cream for you.')
end