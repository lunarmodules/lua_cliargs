#!/usr/bin/lua

--[[
Shows how to use the builtin help functions to create a -h/--help option.
--]]

local cli = require "cliargs"

function help()
  cli:print_help()
  os.exit(0)
end

cli:flag("-h, --help", "prints the help and usage text", help)

local args, err = cli:parse()

if not args then
  print(err)
  os.exit(1)
end
