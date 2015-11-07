local cli = require('cliargs')

cli:set_name('test-command')
cli:argument('ROOT', '...')

return cli:parse()