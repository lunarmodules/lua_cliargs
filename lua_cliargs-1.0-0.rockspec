package = "lua_cliargs"
version = "1.0-0"
source = {
   url = "https://github.com/downloads/amireh/lua_cliargs/lua_cliargs-1.0.tar.gz"
}
description = {
   summary = "A command-line argument parser.",
   detailed = [[
      This module adds support for accepting CLI
      arguments easily using multiple notations and argument types.

      cliargs allows you to define required, optional, and flag arguments.
   ]],
   homepage = "https://github.com/amireh/lua_cliargs",
   license = "MIT/X11" -- or whatever you like
}
dependencies = {
   "lua >= 5.1"
   -- If you depend on other rocks, add them here
}
build = {
   -- We'll start here.
   type = "builtin",
   modules = {
      cliargs = "cli.lua"
   }
}