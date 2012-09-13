local cli = require "cliargs"

cli:set_name("cli_example.lua")

-- Required arguments:
  cli:add_argument("INPUT", "path to the input file")
  -- cli:add_argument("OUTPUT", "path to the output file") -- Using an alias for add_argument

-- Optional arguments:
  cli:add_option("-c, --compress=FILTER", "the filter to use for compressing output: gzip, lzma, bzip2, or none", nil, "gzip")
  cli:add_option("-o FILE", "path to output file", nil, "/dev/stdout")

-- Flags: a flag is a boolean option. Defaults to false
  -- A flag with short-key notation only
  cli:add_flag("-d", "script will run in DEBUG mode")
  -- A flag with both the short-key and --expanded-key notations
  cli:add_flag("-v, --version", "prints the program's version and exits")
  -- A flag with --expanded-key notation only
  cli:add_flag("--verbose", "the script output will be very verbose")

-- Parses from _G['arg'], it's destructive; the table will be empty when the parser is done
local args = cli:parse_args()

if not args then
  -- something wrong happened and an error was printed
  return
end

-- argument parsing was successful, arguments can be found in `args`
-- for k,item in pairs(args) do print(k .. " => " .. tostring(item)) end

-- checking for flags: is -v or --version set?
if args["v"] then
  return print("cli_example.lua: version 1.2.1")
end

print("Input file: " .. args["INPUT"])
print("Output file: " .. args["o"])
print("Compressing? " .. (args["c"] == "none" and "No" or "Yes, using " .. args['c']))
