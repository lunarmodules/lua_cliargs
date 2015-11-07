local cli = require('cliargs')

cli:set_name('git-log')
cli:set_description('Show commit logs')

cli:flag('--[no-]follow', 'Continue listing the history of a file beyond renames (works only for a single file).')

local args, err = cli:parse()

if err then
  return print(err)
end

print("git-log: follow?", args.follow)