## 3.0.0

- new hook `on_error` for installing a custom parse error handler
- the module is now more flexible with option definitions (notations like `-key VALUE` or `--key=VALUE`)
- options using the short-key notation can be specified using `=` as a value delimiter (e.g. `-c=lzma` as well as `-c lzma`)
- `--help` or `-h` will now cause the help listing to be displayed no matter where they are (previously, it only happened if they were the first option)