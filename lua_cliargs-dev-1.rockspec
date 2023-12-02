local package_name = "lua_cliargs"
local package_version = "dev"
local rockspec_revision = "1"
local github_account_name = "lunarmodules"
local github_repo_name = package_name

rockspec_format = "3.0"
package = package_name
version = package_version .. "-" .. rockspec_revision

source = {
   url = "git+https://github.com/" .. github_account_name .. "/" .. github_repo_name .. ".git"
}
if package_version == "dev" then source.branch = "master" else source.tag = "v" .. package_version end

description = {
   summary = "A command-line argument parsing module for Lua",
   detailed = [[
      This module adds support for accepting CLI arguments easily using multiple
      notations and argument types.

      cliargs allows you to define required, optional, and flag arguments.
   ]],
   homepage = "https://github.com/"..github_account_name.."/"..github_repo_name,
   issues_url = "https://github.com/"..github_account_name.."/"..github_repo_name.."/issues",
   license = "MIT"
}

dependencies = {
   "lua >= 5.1"
}

test_dependencies = {
   "busted",
   "dkjson",
   "inifile",
   "yaml",
}

test = {
   type = "busted",
}

build = {
   type = "builtin",
   modules = {
      ["cliargs"] = "src/cliargs.lua",
      ["cliargs.config_loader"] = "src/cliargs/config_loader.lua",
      ["cliargs.constants"] = "src/cliargs/constants.lua",
      ["cliargs.core"] = "src/cliargs/core.lua",
      ["cliargs.parser"] = "src/cliargs/parser.lua",
      ["cliargs.printer"] = "src/cliargs/printer.lua",
      ["cliargs.utils.disect"] = "src/cliargs/utils/disect.lua",
      ["cliargs.utils.disect_argument"] = "src/cliargs/utils/disect_argument.lua",
      ["cliargs.utils.filter"] = "src/cliargs/utils/filter.lua",
      ["cliargs.utils.lookup"] = "src/cliargs/utils/lookup.lua",
      ["cliargs.utils.shallow_copy"] = "src/cliargs/utils/shallow_copy.lua",
      ["cliargs.utils.split"] = "src/cliargs/utils/split.lua",
      ["cliargs.utils.trim"] = "src/cliargs/utils/trim.lua",
      ["cliargs.utils.wordwrap"] = "src/cliargs/utils/wordwrap.lua",
   }
}
