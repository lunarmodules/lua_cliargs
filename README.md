# cliargs

[![travis-ci status](https://secure.travis-ci.org/amireh/lua_cliargs.png)](http://travis-ci.org/#!/amireh/lua_cliargs/builds)

cliargs is a command-line argument parser for Lua. It supports 4 types of arguments:

1. required arguments
1. optional arguments with different notations: `-short-key VALUE` and/or `--expanded-key=VALUE`
1. optional "flag" arguments (on/off options)
1. a single optional "splat" argument which can be repeated (must be the last argument)

Options can have default values of any kind; strings, nil, numbers, or tables.

> **Warning: Backward Compatibility Breakage**
> 
> As of version 2.0, support for overridden keys (or references) has been dropped.
> Since duplicate-keyed options are no longer allowed, you must access each option
> by its key:
>
>  1. `-short-key` notations, like `-i`, are accessed using `my_args.i`
>  2. `--expanded-key` notations, like `--input`, are accessed using `my_args.input`
>  3. mixed notations such as `-i, --input` are accessed using either key

## Usage Example

> See `example.lua` for a more up-to-date reference.

The following script will define 4 arguments for the program called `test.lua`:

* a required argument identified as `ROOT`
* an optional argument that points to an output file which can be specified using `-o FILE`
* another optional argument that points to an input file which can be specified using two different notations:
 * `-i FILE`
 * `--input=FILE`
* an optional flag argument `-v` or `--version` whose value will be set to `true` if it was specified

```lua
local cli = require "cliargs"
cli:set_name("example.lua")
cli:add_argument("ROOT", "path to where root scripts can be found")
cli:add_option("-o FILE", "path to the output file")
cli:add_option("-i, --input=FILE", "path to an input file", "/dev/stdin")
cli:add_flag("-v, --version", "prints the program's version and exits")

local args = cli:parse_args()
if not args then
  -- something wrong happened and an error was printed
  return
end

-- argument parsing was successful, arguments can be found in `args`
for k,item in pairs(args) do print(k .. " => " .. tostring(item)) end

-- checking for flags: is -v or --version set?
if args["v"] then
  return print("example.lua: version 0.0.0")
end

print("Input file: " .. args.input)
print("Output file: " .. args["o"])
```

**Accessing arguments**

All types of arguments must specify a *key*. In the case of required arguments, the keys are only used in the help listings. However, for optional arguments, they are mandatory and only the *--extended-key* notation is optional.

Accessing argument values can be done using the key with the leading dashes omitted (`-` or `--`). When defining an option to use both the -short-key and --expanded-key notations, you can access it using either key; they'll both be defined.

## Help listings `--help`

A help listing will be automatically generated and accessed using the `--help` argument. You can also force its display in the code using `cli:print_help()`.

This is how it looks like for our example:

```bash
Usage: test.lua [OPTIONS]  root 

Required arguments: 
  ROOT                 path to where root scripts can be found

Optional arguments: 
  -o FILE              path to the output file (default: ) 
  -i, --input=FILE     path to an input file (default: ) 
  -v, --version        prints the program's version and exits 
```

## Validations

### Runtime argument validation

From a parsing point of view, there are 3 cases that need to be handled which are outlined below. If I missed something, please open a ticket!

**Missing a required argument**

```bash
>> lua test.lua
test.lua: error: missing arguments, at least 1 argument(s) must be specified; re-run with --help for usage.
Usage: test.lua [OPTIONS]  root
```

**Missing value for an optional argument**

```bash
>> lua test.lua /my_root -i
test.lua: error: missing argument value in '-i FILE'; re-run with --help for usage.
```

**Unknown arguments**

```bash
>> lua test.lua /my_root -f
test.lua: error: unknown option -f; re-run with --help for usage.
```

### Some sanity guards

In the following cases, `cliargs` will report an error to you and terminate the running script:

1. flag options can not accept a value: `cli:add_flag('-v VERSION')`
2. duplicate keys are not allowed: defining two options with the key `--input` will be rejected

## Tests

Running test specs is done using [busted](http://olivinelabs.com/busted/). You can install it using [LuaRocks](http://www.luarocks.org/), and then just call it with the `spec` folder:

```bash
luarocks install busted
cd /path/to/lua_cliargs/
busted spec
```

## Contributions

If you come across a bug and you'd like to patch it, please fork the repository, commit your patch, and request a pull.

**For collaborators**

To deploy a new version, you must bump the rockspec and do a few things:

1. rename the rockspec to reflect the new version (by incrementing the minor version, for example)
2. edit the rockspec to point to the tarball that contains the new version (which also must follow the same naming convention)
3. bump the version stored in the variable `cli._VERSION` in the bottom of the script `src/cliargs.lua`
4. create the tarball using the helper bash script `tarballs/create_tarball.sh`: invoke it with two parameters: the MAJOR version and the MINOR one, ie: `./create_tarball.sh 1 4` to create a 1.4 versioned tarball of the repository
5. add the new tarball to the Downloads of the repository so Luarocks can find it

## Thanks to

Many thanks to everyone who reported bugs, provided fixes, and added entirely new features:

1. [Thijs Schreijer](https://github.com/Tieske)
2. [Jack Lawson](https://github.com/ajacksified)
3. [Robert Andrew Ditthardt](https://github.com/DorianGray)

*If I missed you, don't hesitate to update this file or just email me.*

## Reference

A function reference was generated using [LunaDoc](http://jgm.github.com/lunamark/lunadoc.1.html) which can be found [here](http://lua-cliargs.docs.mxvt.net).

## License

The code is released under the MIT terms. Feel free to use it in both open and closed software as you please.

Copyright (c) 2011-2012 Ahmad Amireh

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
