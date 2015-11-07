local cli = require('cliargs')

cli:set_name('git')
cli:set_description('the stupid content tracker')

cli
  :command('diff', 'Show changes between commits, commit and working tree, etc')
  :splat('path', 'This form is to view the changes you made relative to the index (staging area for the next commit)', nil, 999)
  :flag('-p, --patch', 'This form is to view the changes you made relative to the index (staging area for the next commit)', true)
  :action(function(options)
    -- diff implementation goes here
    print("git-diff called with:", options.path, options.flag, options.patch)
  end)


cli:command('log'):file('examples/04_commands--git-log.lua')

local _, err = cli:parse()

if err then
  return print(err)
end