local args = nil
do
  local cli = require "cli"
  cli:set_name("test.lua")
  cli:add_arg("root", "path to where root scripts can be found", "root_path")
  
  cli:add_opt("-i", 
    "path to an HTML file which will be dTE-ed", 
    "input_path", 
    { expanded_key = "--input", value = "FILE" })
  -- cli:add_opt("-o", "--output", "FILE", "the dTE-ed response will be saved in this file", "output_path", "stdout")

  -- cli:print_usage()
  args = cli:parse_args()
  if args then
    for k,item in pairs(args) do print(k .. " => " .. item) end
  else
    return
  end
  -- return
end