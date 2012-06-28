local args = nil
do
  local cli = require "cli"
  cli:set_name("test.lua")
  cli:add_argument("root", "path to where root scripts can be found", "root_path")
  cli:add_option("-i, --input=FILE", "path to an HTML file which will be dTE-ed", "input_path")
  cli:add_flag("-v, --version", "prints the program's version and exits")
  -- cli:print_usage()
  args = cli:parse_args()
  if args then
    for k,item in pairs(args) do print(k .. " => " .. tostring(item) ) end
  else
    return
  end
  -- return
end