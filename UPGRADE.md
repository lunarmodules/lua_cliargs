## Upgrading from 2.x to 3.0

- `cli._VERSION` has been renamed to `cli.VERSION`

**Function renames**

The functions for defining arguments of all types have been renamed to drop the
`_add` prefix from their names. This affects the following functions:

- `cli:add_argument` has been renamed to `cli:argument`
- `cli:add_option` has been renamed to `cli:option`
- `cli:add_flag` has been renamed to `cli:flag`
- `cli:optarg` has been renamed to `cli:splat`

**Function alias removals**

- `cli:add_opt` has been removed. Use `cli:option` instead
- `cli:add_arg` has been removed. Use `cli:argument` instead
- `cli:parse_args` has been removed. Use `cli:parse` instead

**`cli:parse()` invocation changes**

`cli:parse()` no longer accepts the auxiliary arguments `noprint` and `dump` as the second and third arguments; only one argument is now accepted and that is a custom arguments table. If left unspecified, we use the global `_G['arg']` program argument table as usual.

So, the new signature is:

`cli:parse(args: table) -> table`

- to make the parser silent, use `cli:set_silent(true)` before invoking the parser
- to generate the internal state dump, a runtime argument `--__DUMP__` must be passed as the first argument

**Private function are now hidden**

Hopefully you weren't relying on any of these because they are no longer exposed, and they weren't documented. The affected previous exports are:

- `cli:__lookup()`
- `cli:__add_opt()`
