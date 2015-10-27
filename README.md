# lua_cliargs

[![travis-ci status](https://secure.travis-ci.org/amireh/lua_cliargs.png)](http://travis-ci.org/#!/amireh/lua_cliargs/builds)

cliargs is a command-line argument parser for Lua. It supports several types of arguments:

1. required arguments
2. optional arguments with different notations: `-short-key VALUE` and/or `--expanded-key=VALUE`
3. optional arguments with multiple-values that get appended to a list
4. optional "flag" arguments (on/off options) with notations: `-short-key` and/or `--expanded-key`
5. a single optional "splat" argument which can be repeated (must be the last argument)

Optional arguments can have default values (strings), flags always default to 'true'.

## Usage Examples

See the examples under the `examples/` directory.

## API

#### cli:argument(key: string, desc: string[, callback: fn]) -> nil

Defines a required argument.

Required arguments do not take a symbol like `-` or `--`, may not have a default value, and are parsed in the order they are defined.

For example:

```lua
cli:argument('INPUT', 'path to the input file')
cli:argument('OUTPUT', 'path to the output file')
```

At run-time, the arguments have to be specified using the following notation:

```bash
$ ./script.lua ./main.c ./a.out
```

If the user does not pass a value to _every_ argument, the parser will raise an error.

#### cli:option(key: string, desc: string[, default: *, callback: fn]) -> nil

Defines an optional argument.

Options can be specified in a number of ways on the command-line. As an example, let's assume we have a `compress` option that may be one of `gzip` (default,) `lzma`, or something else:

```lua
cli:option('-c, --compress=VALUE', 'compression algorithm to use', 'gzip')
```

At run-time, the option may be specified using any of the following notations:

```bash
$ ./script.lua -c lzma
$ ./script.lua -c=lzma
$ ./script.lua --compress lzma
$ ./script.lua --compress=lzma
$ ./script.lua --compress= # this overrides the default of `gzip` to `nil`
```

#### cli:flag(key: string, desc: string[, default: *, callback: fn]) -> nil

Defines an optional "flag" argument.

Flags are a special subset of options that can either be `true` or `false`. 

For example:

```lua
cli:flag('-q, --quiet', 'Suppress output.', true)
```

At run-time:

```bash
$ ./script.lua --quiet
$ ./script.lua -q
```

Passing a value to a flag raises an error:

```bash
$ ./script.lua --quiet=foo
$ echo $? # => 1
```

Flags may be _negatable_ by prepending `[no-]` to their key:

```lua
cli:flag('-c, --[no-]compress', 'whether to compress or not', true)
```

Now the user gets to pass `--no-compress` if they want to skip compression, or either specify `--compress` explicitly or leave it unspecified to use compression.

#### cli:splat(key: string, desc: string[, default: *, maxcount: number, callback: fn]) -> nil

Defines a "splat" (or catch-all) argument.

This is a special kind of argument that may be specified 0 or more times, the values being appended to a list.

For example, let's assume our program takes a single output file and works on multiple source files:

```lua
cli:argument('OUTPUT', 'path to the output file')
cli:splat('INPUTS', 'the sources to compile', nil, 10) -- up to 10 source files
```

At run-time, it could be invoked as such:

```bash
$ ./script.lua ./a.out file1.c file2.c main.c
```

If you want to make the output optional, you could do something like this:

```lua
cli:option('-o, --output=FILE', 'path to the output file', './a.out')
cli:splat('INPUTS', 'the sources to compile', nil, 10)
```

And now we may omit the output file path:

```bash
$ ./script.lua file1.c file2.c main.c
```

#### cli:parse(args: table) -> table

Parses the arguments table. This is the primary routine. The return value is a table containing all the arguments, options, flags, and splat arguments that were specified or had a default (where applicable).

The table keys are the keys you used to define the arguments (both short and expanded notations like `-q` => `q` and `--quiet` => `quiet`).

Example:

```lua
local args
args = cli:parse() -- uses the global arguments table
args = cli:parse({ '--some-option', 'arg' })
```

**Accessing arguments**

All types of arguments must specify a *key*. In the case of required arguments, the keys are only used in the help listings. However, for optional arguments, they are mandatory (either *--key* or *--extended-key* must be specified, the other is optional).

The `cli:parse()`  method will parse the command line and return a table with results. Accessing argument or option values in this table can be done using the key with the leading dashes omitted (`-` or `--`). When defining an option (or a flag) , you can access it using either key or expanded-key; they'll both be defined.

See the examples for more on this.

#### cli:print_help() -> string

Prints the help listing. This is automatically done if the user specifies `--help` as an argument at run-time.

An example is shown in the help-listing section below.

#### cli:print_usage() -> string

Prints a subset of the full help-listing showing only the usage/invocation format. For example:

```
Usage: cli_example.lua [OPTIONS]  INPUT  [OUTPUT-1 [OUTPUT-2 [...]]]
```

#### cli:set_name(name: string) -> nil

Allows you to specify a name for the program which will be used in the help listings and error messages.

#### cli:set_description(desc: string) -> nil

Allows you to specify a short description of the program to display in the help listing.

#### cli:set_colsz(key_columns: number, desc_columns: number) -> nil

Specifies the formatting options for the help listings.

The first argument is how wide, in characters, should the first column that contains the keys/names of the arguments be.

The second argument denotes how wide, in characters, should the second column that contains the argument descriptions be.

By default, these are set to `0` which means cliargs will auto-detect the best column sizes. The description column will be capped to a width of 72 characters.

## Help listings `--help`

A help listing will be automatically generated and accessed using the `--help` argument. You can also force its display in the code using `cli:print_help()`.

This is the result for our example (see `examples/00_general.lua`):

```
Usage: cli_example.lua [OPTIONS]  INPUT  [OUTPUT-1 [OUTPUT-2 [...]]]

ARGUMENTS:
  INPUT                 path to the input file (required)
  OUTPUT                multiple output paths (optional, default:
                        /dev/stdout)

OPTIONS:
  -c, --compress=FILTER the filter to use for compressing output: gzip,
                        lzma, bzip2, or none (default: gzip)
  -o FILE               path to output file (default: /dev/stdout)
  -d                    script will run in DEBUG mode
  -v, --version         prints the program's version and exits
  --verbose             the script output will be very verbose
```

## Validations

### Runtime argument validation

From a parsing point of view, there are 3 cases that need to be handled which are outlined below. If I missed something, please open a ticket!

**Missing a required argument**

```
$ lua examples/00_general.lua
cli_example.lua: error: bad number of arguments; 1-4 argument(s) must be specified, not 0; re-run with --help for usage.
```

**Missing value for an optional argument**

```
$ lua examples/00_general.lua --compress inputfile
cli_example.lua: error: option --compress requires a value to be set; re-run with --help for usage.
```

**Unknown arguments**

```
$ lua examples/00_general.lua -f inputfile
cli_example.lua: error: unknown/bad flag; -f; re-run with --help for usage.
```

### Some sanity guards

In the following cases, `cliargs` will report an error to you and terminate the running script:

1. flag options can not accept a value. For example: `cli:add_flag('-v VERSION')` will return an error
2. duplicate keys are not allowed: defining two options with the key `--input` will be rejected

## Tests

Running test specs is done using [busted](http://olivinelabs.com/busted/). You can install it using [LuaRocks](http://www.luarocks.org/), and then just call it with the `spec` folder:

```
luarocks install busted
cd /path/to/lua_cliargs/
busted spec
```

## Contributions

If you come across a bug and you'd like to patch it, please fork the repository, commit your patch, and request a pull.

## Thanks to

Many thanks to everyone who reported bugs, provided fixes, and added entirely new features:

1. [Thijs Schreijer](https://github.com/Tieske)
1. [Jack Lawson](https://github.com/ajacksified)
1. [Robert Andrew Ditthardt](https://github.com/DorianGray)
1. [Oscar Lim](https://github.com/o-lim)

*If I missed you, don't hesitate to update this file or just email me.*

## Changelog

### Changes from 2.5.x 3.0

This major version release contains BREAKING API CHANGES. See the UPGRADE guide for help in updating your code to make use of it.

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

- a new hook was introduced for installing a custom parse error handler: `cli:set_error_handler(fn: function)`. The default will invoke `error()`.
- internal code changes and more comprehensive test-coverage

### Changes from 2.5.1 to 2.5.2

- No longer tracking the (legacy) tarballs in git or the luarocks package. Instead, we use the GitHub release tarballs for each version.

### Changes in 2.4.0 from 2.3-4

1. All arguments now accept a callback that will be invoked when parsing of those arguments was successful
2. (**POSSIBLY BREAKING**) Default value for flags is now `nil` instead of `false`. This will only affect existing behavior if you were explicitly testing unset flags to equal `false` (i.e. `if flag == false then`) as opposed to `if flag then` (or `if not flag then`).
3. Minor bugfixes

### Changes in 2.3.0

1. the parser will now understand `--` to denote the end of optional arguments and will map whatever comes after it to required/splat args
2. `-short VALUE` is now properly supported, so is `-short=VALUE`
3. short-key options can now officially be composed of more than 1 character
4. the parser now accepts callbacks that will be invoked as soon as options are parsed so that you can bail out of parsing preemptively (like for `--version` or `--help` options)
5. options can now accept multiple values via multiple invocations if a table was provided as a default value (passed-in values will be appended to that list)

### Changes in 2.2-0 from 2.1-2

1. the `=` that separates keys from values in the `--expanded-key` notation is no longer mandatory; using either a space or a `=` will map the value to the key (e.g., `--compress lzma` is equal to `--compress=lzma`)

### Changes in 2.0.0 from 1.x.x

1. added the 'splat' argument, an optional repetitive argument for which a maximum number of occurrences can be set
1. removed the reference, arguments are now solely returned by their key/expanded-key (BREAKING!)
1. removed object overhead and the `new()` method as the library will only be used once on program start-up (BREAKING!)
1. after parsing completed successfully, the library will effectively delete itself to free resources (BREAKING!)
1. option/flag is now allowed with only an expanded-key defined
1. Debug aid implemented; adding a first option `--__DUMP__`, will dump the results of parsing the command line. Especially for testing how to use the commandline with arguments containing spaces either quoted or not.
1. the `print_usage()` and `print_help()` now have a 'noprint' parameter that will not print the message, but return it as an error string (`nil + errmsg`)

## License

The code is released under the MIT terms. Feel free to use it in both open and closed software as you please.

Copyright (c) 2011-2015 Ahmad Amireh

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
