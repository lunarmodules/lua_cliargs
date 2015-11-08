var path = require('path');

exports.assetRoot = path.resolve(__dirname, '..');
exports.outputDir = path.resolve(__dirname, 'compiled');
exports.layout = 'single-page';
exports.stylesheet = 'doc/style.less';
exports.title = 'lua_cliargs';
exports.scrollSpying = true;

exports.plugins = [
  require('tinydoc-plugin-lua')({
    source: 'src/**/*.lua'
  })
]