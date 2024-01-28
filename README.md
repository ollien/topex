# Topex

A small TOTP-generating application.

## Why?

Mostly because I wanted to implement the TOTP algorithm for fun. I probably wouldn't use this in any security-sensitive
contexts.

## Building

The CLI application uses [Burrito](https://github.com/burrito-elixir/burrito) to package itself, so you should ensure
its dependencies are installed (notably `zig` and `xz`). You can build the output binary with
`MIX_ENV=prod mix release`.

## Usage
Topex requires a configuration file (located at `./topex.conf`) of the form

```toml
[[keys]]
name = "account1"
key = "JBSWY3DPEHPK3PXP"

[[keys]]
name = "account2"
key = "PXP3KPHEPD3YWSBJ"
```

You can then generate a code using `./topex [key_name]`. Note that this argument is only optional if there is only one
key present. If not, you must specify the TOTP key you want to use to generate the code.
