# Changelog

All notable changes to this project are documented in this file.

The format is based on [keep a changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [semantic versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

* Bundled short options: a single dash followed by a bundle of short options is expanded, so `-abc` is equivalent to `-a -b -c`. A required or defaulted option may end a bundle and will consume the next argument (`-abo file`). Exact multi-character single-dash flags such as `-readonly` still take precedence, and a help flag in any bundle position will short-circuit to showing the help ([#53])

## [0.2.0] - 2026-07-12

### Breaking

* Removed the `shifu_allow_options_anywhere` configuration variable. To pass an argument that starts with a dash, use the newly added end-of-options delimiter, `--` ([#49])

### Added

* Repeatable flags: suffix the variable name with `...` to make the flag repeatable, so each time it is used its argument is accrued instead of overwriting the previous value. A non-empty `<default>` becomes the first item in the list ([#45])
* `shifu_itr_list`: iterate over the arguments accrued by a repeatable flag in a `while` loop; the variable itself is not assigned the values ([#45])
* Equals as an option-value separator: long flags now accept `--flag=value` in addition to a space between the flag and its value ([#39])
* End-of-options delimiter (`--`): a bare `--` stops option parsing, and every argument after it is treated as a non-option argument, even if it begins with `-`. These fill any positional arguments, then overflow into `$@`. Use it to pass a value that starts with a dash, or to forward flags to another command. Tab completion is supported after `--` ([#49])
* Options may now appear after positional arguments, with tab completion support ([#48])

## [0.1.0] - 2026-03-29

### Added

* Initial release: a declarative framework that makes creating powerful CLIs from shell scripts simple, all in a single POSIX shell file with no dependencies
* Commands as the core building block: a DSL of `cmd` functions that shifu uses to build a CLI, run or referenced as subcommands via `shifu_run`
* Command info is specified with functions: `shifu_cmd_name`, `shifu_cmd_subs`, `shifu_cmd_func`, `shifu_cmd_help`, and `shifu_cmd_long`
* Argument parsing: options `shifu_cmd_optb` (binary), `shifu_cmd_optd` (with default), and `shifu_cmd_optr` (required), plus positional and remaining arguments `shifu_cmd_argr` and `shifu_cmd_args`. Options declared in a parent command can be scoped across its subcommands via `:eager:` and `:defer:` modes
* Help string formatting: auto-generated, (sub)command scoped help
* Tab completion for interactive shells, including enumerated values (`shifu_cmd_cpte`), custom completion functions (`shifu_cmd_cptf` with `shifu_add_cpts`), and path completion (`shifu_cmd_cptp`)
* Configuration variables: `shifu_allow_options_anywhere`, `shifu_complete_single_dash_options`, and `shifu_help_flags`
* `shifu_less`: expose the `cmd` functions without the `shifu_` prefix
* Compatibility with POSIX-based shells; tested with ash, bash, dash, ksh, and zsh

[Unreleased]: https://github.com/Ultramann/shifu/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/Ultramann/shifu/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/Ultramann/shifu/releases/tag/v0.1.0

[#53]: https://github.com/Ultramann/shifu/pull/53
[#49]: https://github.com/Ultramann/shifu/pull/49
[#48]: https://github.com/Ultramann/shifu/pull/48
[#45]: https://github.com/Ultramann/shifu/pull/45
[#39]: https://github.com/Ultramann/shifu/pull/39
