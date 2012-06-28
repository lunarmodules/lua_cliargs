local args = nil
do
  local cli = require "cli"
  cli:set_name("test.lua")
  cli:add_arg("root", "path to where root scripts can be found", "root_path")
  
  cli:add_opt("-i", 
    "path to an HTML file which will be dTE-ed", 
    "input_path", 
    { expanded_key = "--input", value = "FILE" })

  cli:add_opt("-v", "prints the program's version and exits", "version", { default = false })


  -- cli:add_opt("-o", "--output", "FILE", "the dTE-ed response will be saved in this file", "output_path", "stdout")

  -- cli:add_flag("-v, --version", "prints the version of test.lua")

  -- cli:print_usage()
  args = cli:parse_args()
  if args then
    for k,item in pairs(args) do print(k .. " => " .. tostring(item) ) end
  else
    return
  end
  -- return
end