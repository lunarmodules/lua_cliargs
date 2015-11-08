## 3.0.0

**More flexible parsing**

- options can occur anywhere now even after arguments (unless the `--` indicator is specified, then no options are parsed afterwards.) Previously, options were accepted only before arguments.
- options using the short-key notation can be specified using `=` as a value delimiter as well as a space (e.g. `-c=lzma` and `-c lzma`)
- the library is now more flexible with option definitions (notations like `-key VALUE` or `--key=VALUE`)
- `--help` or `-h` will now cause the help listing to be displayed no matter where they are (previously, it only happened if they were the first option)

**Re-defining defaults**

It is now possible to pass a table containing default values (and override any 
existing defaults).

The function for doing this is called `cli:load_defaults().`.

This makes it possible to load run-time defaults from a configuration file, for example.

**Other changes**

- ~~a new hook was introduced for installing a custom parse error handler: `cli:set_error_handler(fn: function)`. The default will invoke `error()`.~~
- internal code changes and more comprehensive test-coverage