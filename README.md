<p align="center">
  <img src="./assets/banner-dark.svg#gh-dark-mode-only" width="65%">
  <img src="./assets/banner-light.svg#gh-light-mode-only" width="65%">
</p>

**SH**ell **I**nterface **F**ramework **U**tility, shifu, is a declarative framework that makes creating powerful CLIs from shell scripts simple. Shifu provides:

* argument parsing
* subcommand dispatch
* help string formatting
* tab completion for interactive shells
* compatibility with POSIX-based shells; tested with:
  * ash, bash, dash, ksh, zsh

all in a single POSIX shell file with no dependencies.

Shell scripts are great for gluing terminal programs together. But adding subcommands, scoped options, help strings, and tab completion means a lot of boilerplate that's hard to understand and maintain. Shifu offers an API to describe CLI structure, letting you focus on real functionality.

## Table of contents

* [Installation](#installation)
* [Quickstart](#quickstart)
* [Subcommands](#subcommands)
* [Tab completion](#tab-completion)
* [FAQ](#faq)
* [API](#api)

## Installation

Since shifu is just a single POSIX-compatible script, all you need to do is get a copy of it and either put it in a location on your `PATH` or in the same directory as your CLI script.

```sh
curl -O https://raw.githubusercontent.com/Ultramann/shifu/main/shifu
```

## Quickstart

The core building block in shifu is a command. A command is a function, by convention ending in `_cmd`, that _only_ contains calls to shifu `cmd` functions. Together, these functions form a DSL that shifu uses to build your CLI. Commands are passed to shifu's command runner, `shifu_run`, or referenced as subcommands.

Below is a very minimal, introductory shifu CLI script.

[`examples/intro`](/examples/intro)

```sh
. "${0%/*}"/shifu || exit 1

intro_cmd() {
  shifu_cmd_name intro
  shifu_cmd_func intro_function
  shifu_cmd_help "An introduction shifu cli"
  shifu_cmd_long "This command function will invoke intro_function which prints
an option value provided by '-o' or '--option', defaults to none"
  shifu_cmd_optd -o --option -- OPTION none "Example option to echo"
}

intro_function() {
  echo "$OPTION"
}

shifu_run intro_cmd "$@"
```

Calling this CLI, we can see how `shifu_run` parses `-o shifu` into the variable `OPTION` and calls `intro_function`; and also automatically generates help strings.

```txt
$ examples/intro
none
$ examples/intro -o shifu
shifu
$ examples/intro --help
An introduction shifu cli

This command function will invoke intro_function which prints
an option value provided by '-o' or '--option', defaults to none

Options
  -o, --option [OPTION]
    Example option to echo
    Default: none
  -h, --help
    Show this help
```

The diagram below shows how shifu connects this CLI script to parse the command line arguments and print the value `shifu` in `intro_function`.

```
       examples/intro -o shifu ───────────────┐
                  ▲    ▲                      │
                  │    └────────────────┐     │
                  └──────────┐          │     │
    intro_cmd() {            │          │     │
      shifu_cmd_name intro ──┘          │     │
┌──── shifu_cmd_func intro_function     │     │
│     shifu_cmd_optd -o --option -- \ ──┘     │
│       OPTION none "Example option to echo"  │
│   }     ▲                                   │
│         └───────────────────────────────────┘
│
└─► intro_function() {
      echo "$OPTION"
    }
```

This example only demonstrates how to parse one option with a default value, but shifu supports several option and argument types: binary options, options with defaults, required options, positional arguments, and remaining arguments. See the [Option and argument functions](#option-and-argument-functions) API section for details.

## Subcommands

Shifu supports subcommands for grouping related functionality. Use `shifu_cmd_subs` instead of `shifu_cmd_func` to reference subcommand, `_cmd`, functions by name. When called, `shifu_run` recursively matches command line arguments against the names declared with `shifu_cmd_name` in each subcommand. Once a command is found using `shifu_cmd_func`, `shifu_run` calls the function by name as shown in the quickstart.

Here's what the minimal structure of a subcommand CLI looks like, with help strings omitted to highlight the subcommand and function references.

```sh
root_cmd() {
  shifu_cmd_name root
  shifu_cmd_subs sub_cmd   # -┐
}                          #  │
                           #  │
sub_cmd() {  # <──────────────┘
  shifu_cmd_name sub
  shifu_cmd_func sub_func  # -┐
}                          #  │
                           #  │
sub_func() { # <──────────────┘
  echo "Hello from sub_func"
}

shifu_run root_cmd "$@"
```

If this script were saved as `root` and called with `root sub`, `shifu_run` would match `sub` against the name declared in `sub_cmd` and dispatch to `sub_func`.

```txt
$ root sub
Hello from sub_func
```

Arguments and help strings are scoped to each subcommand. Parent commands can also declare shared options once instead of repeating them in each subcommand, and control when those options are parsed, see the [Option and argument functions notes](#notes) API section for details.

Below is a demo of [`examples/dispatch`](/examples/dispatch), a CLI with two subcommands, `hello` and `echo`, each with their own arguments. Annotated source code of the CLI can be found in the expandable section below the demo.

![Quickstart](/assets/dispatch_demo.gif)

<details>

<summary><b>Source code and walkthrough</b></summary>

Note, this example calls `shifu_less` after sourcing `shifu` to provide a version of the `shifu_cmd` functions without the `shifu_` prefixes.

[`examples/dispatch`](/examples/dispatch)

```sh
#! /bin/sh

# Source, "import", shifu
. "${0%/*}"/shifu && shifu_less || exit 1

# Write root command
dispatch_cmd() {
  # Name the command
  cmd_name dispatch
  # Add subcommands
  cmd_subs hello_cmd echo_cmd
  # Add help for the command
  cmd_help "A dispatch shifu example"
  # Add long help for the command
  cmd_long "An example shifu cli demonstrating
  * subcommand dispatch
  * argument parsing
  * scoped help generation"
  # Add deferred binary option, inherited by subcommands
  cmd_optb :defer: -D --deferred -- DEFERRED false true "Deferred binary option"
}

# Write first subcommand, referenced in `cmd_subs` above
hello_cmd() {
  cmd_name hello
  # Add target function
  cmd_func dispatch_hello
  cmd_help "A hello world subcommand"
  cmd_long "A subcommand that prints greeting with arguments"
  # Add option, will populate variable `NAME` when parsing cli args
  # NAME defaults to 'mysterious user' if -n/--name aren't provided
  cmd_optd -n --name -- NAME "mysterious user" "Name to greet"
}

# Write first subcommand target function
dispatch_hello() {
  [ "$DEFERRED" = true ] && message="☝ " || message=""
  echo "${message}Hello, $NAME!"
}

# Write second subcommand, referenced in `cmd_subs` above
echo_cmd() {
  cmd_name echo
  cmd_func dispatch_echo
  cmd_help "An echo subcommand"
  cmd_long "A subcommand that prints results of parsed arguments"

  # Add options and positional argument
  cmd_optr -r --required -- REQUIRED   "Example required option w/ argument"
  cmd_optd -d --default  -- DEFAULT    "default" "Example option w/ argument"
  cmd_argr                  POSITIONAL "Example positional argument"
}

# Write second subcommand target function
dispatch_echo() {
  # Use variables populated by option/argument functions
  echo "Deferred binary option: $DEFERRED"
  echo "Required option:        $REQUIRED"
  echo "Option w/ default:      $DEFAULT"
  echo "Positional argument:    $POSITIONAL"
}

# Run root command passing all script arguments
shifu_run dispatch_cmd "$@"
```

The diagram below shows how shifu is connecting together this CLI script to print the value `☝ Hello, World!` in `dispatch_hello`.

```
┌───────────── sets to ─────────────┐
│ ┌──────────── true ──────────────┐│
│ │                                ▼│
│ │        examples/dispatch hello -D --name World ──────────────────────┐
│ │                     ▲      ▲         ▲                               │
│ │                     │      │         └─────────────────────────────┐ │
│ │                     │      └────────────────────────────────┐      │ │
│ │ dispatch_cmd() {    │              ┌──► hello_cmd() {       │      │ │
│ │   cmd_name dispatch ┘              │      cmd_name hello ───┘      │ │
│ │   cmd_subs hello_cmd echo_cmd ─────┘  ┌── cmd_func dispatch_hello  │ │
│ └── cmd_optb :defer: -D --deferred \ ┌──┘ cmd_optd -n --name \ ──────┘ │
└────►  -- DEFERRED false true \       │  ┌──►  -- NAME "mysterious \    │
        "Deferred binary option"       │  │     user" "Name to greet"    │
    }                                  │  │ }                            │
      ┌────────────────────────────────┘  └──────────────────────────────┘
      │
      └─► dispatch_hello() {
            [ "$DEFERRED" = true ] && message="☝ " || message=""
            echo "${message}Hello, $NAME!"
          }
```

</details>

## Tab completion

Since shifu knows all about the structure of your CLI it can generate tab completion code for interactive shells that support it, bash and zsh.

By default, subcommand and option names can be tab completed. Shifu also provides `cmd` functions for completing option values and positional arguments with static enumerations, dynamic functions, or file system paths, see the [Completion functions](#completion-functions) API section for details.

Below is a demo of [`examples/tab`](/examples/tab) showing tab completion capabilities. Source code and instructions to run the example can be found in the expandable section below the demo.

![Tab completion](/assets/tab_demo.gif)

<details>

<summary><b>Source code and running instructions</b></summary>

[`examples/tab`](/examples/tab)

```sh
#! /bin/sh

. "${0%/*}"/shifu && shifu_less || exit 1

tab_cmd() {
  cmd_name tab
  cmd_help "A tab completion shifu example"
  cmd_long "An example shifu cli demonstrating completions for
  * subcommand names
  * option names
  * option values with
    * enum completions
    * function completions
    * path completions"
  cmd_subs completion_cmd demo_cmd
}

completion_cmd() {
  cmd_name completion
  cmd_help "Main command with example options and tab completion capabilities"
  cmd_func no_op

  cmd_optd -e --enum -- ENUM_COMP enum_comp "Enum completion"
  cmd_cpte magic value
  cmd_optd -f --func -- FUNC_COMP func_comp "Function completion, file extensions"
  cmd_cptf file_extension_completions
  cmd_argr              PATH_COMP "Path completion"
  cmd_cptp :files:
}

file_extension_completions() {
  # dynamically complete with extensions from files in current directory
  shifu_add_cpts "$(ls -1 | grep '\.' | sed 's/.*\.//' | sort -u)"
}

demo_cmd() {
  cmd_name demo
  cmd_help "No-op command to show multiple subcommand completion options"
  cmd_func no_op
}

no_op() { :; }

shifu_run tab_cmd "$@"
```

If you'd like to test the tab completion from this example you can easily do so from a bash or zsh (requires autoloading `compinit`) terminal by running

```sh
export PATH="$PATH:$(pwd)/examples"
```

so your shell can find the example `tab` CLI, and

```sh
eval "$(examples/tab --tab-completion bash)"
# or, choose for your shell
eval "$(examples/tab --tab-completion zsh)"
```

then tabbing along to the beat.

</details>

### Enable

1. Ensure your CLI is in a directory on your shell's `PATH`
1. Ensure your CLI has access to shifu; either by putting shifu in the same `PATH` directory as your CLI or adding shifu to another `PATH` directory
1. If you're using zsh, ensure that you've loaded and run `compinit` before the following eval call in your zshrc file
1. Add the following line to your shell's rc file, replacing `<your-cli>` with the name of your CLI and `<shell>` with a supported shell: bash or zsh
   ```sh
   eval "$(<your-cli> --tab-completion <shell>)"
   ```

These instructions can also be found by running
```sh
<your-cli> --tab-completion help
```

## FAQ

* Why? This isn't what shell scripts are for.
  * Fair. However, sometimes a shell is all you want to require your users to have while still enabling a sophisticated CLI UX; shifu can help deal with the CLI boilerplate in those situations and let you focus on real functionality
  * Plus. Consider the following quote

    > If you only do what you can do, then you will never be better than what you are.
    >
    > \- Master Shifu, Kung Fu Panda
    
    Shifu gives CLI shell scripts the opportunity to be better than they are
  * Finally. I want to use something like shifu, maybe others do too

* How does shifu name its variables/functions, will they collide with those in my script?
  * Shifu takes special care to prefix all variables/functions with `shifu` or `_shifu`
  * Calling `shifu_less` after sourcing shifu will create versions of all the `cmd` functions without the `shifu` prefix. This makes command code less busy, but adds function names that are more likely to cause a collision with those in your script

* What's with the `. "${0%/*}"/shifu || exit 1`?
  * `.` is the POSIX source command; it executes a file in the current shell, making shifu's functions available to your script, akin to importing
  * `"${0%/*}"` is parameter expansion that strips the filename from `$0` (the script path), leaving just the directory. This lets your script find shifu relative to itself rather than relying on `PATH`
  * `|| exit 1` exits the script if sourcing fails (e.g., shifu not found), preventing cryptic errors later
  * If shifu is on your `PATH`, you can simply use `. shifu || exit 1`

## API

* [Command runner](#command-runner)
* [Command definition functions](#command-definition-functions)
* [Option and argument functions](#option-and-argument-functions)
* [Completion functions](#completion-functions)
* [Configuration](#configuration)
* [Miscellaneous](#miscellaneous)

### Command runner

#### `shifu_run`
* Called at the end of a CLI script
* Takes the name of a command function, those ones that end in `_cmd` by convention, and all script arguments, `"$@"`
* Dispatches call by parsing arguments in `"$@"` based on information in command function
* Parses arguments that match subcommand names until the subcommand specifies a function to call with `shifu_cmd_func`
* Parses all unparsed arguments into variables declared in option and argument function calls
* Calls the function in `shifu_cmd_func` passing any still unparsed arguments
* Example
  ```sh
  shifu_run root_cmd "$@"
  ```

### Command definition functions

#### `shifu_cmd_name`
* Name used to reference command from command line arguments
* When the command is passed to `shifu_run` this name must match the name of the program for tab completion to work
* When the command is a subcommand the name is used to parse command line arguments
* Example
  ```sh
  shifu_cmd_name shifu
  ```

#### `shifu_cmd_subs`
* Subcommand function names to which the current command can route
* Example
  ```sh
  shifu_cmd_subs subcommand_one_cmd subcommand_two_cmd
  ```

#### `shifu_cmd_func`
* Name of function to run when command is invoked
* The function will be passed all command line arguments that weren't parsed while identifying the command
* Example
  ```sh
  shifu_cmd_func function_to_run
  ```

#### `shifu_cmd_help`
* Brief help string for the command
* Added in help above the help for command arguments
* Added to help when listing a command's subcommands
* Example
  ```sh
  shifu_cmd_help "Terse string to help users"
  ```

#### `shifu_cmd_long`
* Long help string for the command
* Added in help after brief help string
* Example
  ```sh
  shifu_cmd_long "Verbose string to really help users"
  ```

### Option and argument functions

There are five option and argument declaration functions:

| Type     | Function         | Parses                       |
|----------|------------------|------------------------------|
| Option   | `shifu_cmd_optb` | Binary option                |
| Option   | `shifu_cmd_optd` | Option with default          |
| Option   | `shifu_cmd_optr` | Required option              |
| Argument | `shifu_cmd_argr` | Required positional argument |
| Argument | `shifu_cmd_args` | Remaining arguments          |

Option functions (`shifu_cmd_optb`, `shifu_cmd_optd`, `shifu_cmd_optr`) parse flagged arguments into variables. They take one or more flags (e.g. `-v`, `--verbose`) before a required `--` separator, followed by parsing configuration. Argument functions (`shifu_cmd_argr`, `shifu_cmd_args`) parse positional arguments by order of declaration.

All option and argument functions accept a `variable` argument, the shell variable name that will be set when parsing, and a `help` string used in generated help output.

#### `shifu_cmd_optb`
* Binary option
* Variable is assigned a value depending on whether or not the option flag is set
* Signature
  ```sh
  shifu_cmd_optb <flags> -- <variable> <default> <set_value> <help>
  ```
* Example
  ```sh
  shifu_cmd_optb -v --verbose -- VERBOSE false true "Verbose output"
  ```
  ```txt
  cli             # VERBOSE=false
  cli --verbose   # VERBOSE=true
  ```

#### `shifu_cmd_optd`
* Option with default
* Variable has a default value which can be overwritten with the option flag and a following argument
* Signature
  ```sh
  shifu_cmd_optd <flags> -- <variable> <default> <help>
  ```
* Example
  ```sh
  shifu_cmd_optd -o --output -- OUTPUT "out" "Output file"
  ```
  ```txt
  cli                   # OUTPUT="out"
  cli --output result   # OUTPUT="result"
  ```

#### `shifu_cmd_optr`
* Required option
* Variable must be set with the option flag and a following argument, error if not provided
* Signature
  ```sh
  shifu_cmd_optr <flags> -- <variable> <help>
  ```
* Example
  ```sh
  shifu_cmd_optr -e --env -- ENV "Operating environment"
  ```
  ```txt
  cli             # error: missing required option
  cli --env dev   # ENV="dev"
  ```

#### `shifu_cmd_argr`
* Required positional argument
* Variable is set from the next unparsed argument
* Signature
  ```sh
  shifu_cmd_argr <variable> <help>
  ```
* Example
  ```sh
  shifu_cmd_argr TARGET "Target to process"
  ```
  ```txt
  cli              # error: missing required argument
  cli myfile.txt   # TARGET="myfile.txt"
  ```

#### `shifu_cmd_args`
* Remaining arguments
* Zero or more unparsed arguments passed to the target function (specified by `shifu_cmd_func`) via `$@`
* Signature
  ```sh
  shifu_cmd_args <help>
  ```
* Example
  ```sh
  shifu_cmd_args "Additional arguments"
  ```
  ```txt
  cli                 # $@ is empty
  cli one two three   # $@ = one two three
  ```

#### Notes

The signatures and examples above are for leaf commands (those using `shifu_cmd_func`). When you have options that are shared across subcommands, like a `--verbose` flag, you can declare them once in a parent command (those using `shifu_cmd_subs`) instead of repeating them in every subcommand.

Option functions called in a parent command require a mode as the first argument. The mode changes when the option will be parsed, aka when it will be provided by the CLI user. The two available modes are:
* `:defer:` - option parsing is deferred until the leaf command, so the option can be provided alongside subcommand options
  ```sh
  shifu_cmd_optb :defer: -v --verbose -- VERBOSE false true "Verbose output"
  ```
  ```txt
  cli sub --verbose
  ```
* `:eager:` - option parsing happens before subcommand dispatch, so the option must be provided before the subcommand name
  ```sh
  shifu_cmd_optd :eager: -c --config -- CONFIG "default" "Config file"
  ```
  ```txt
  cli --config myconfig sub
  ```

Positional and remaining argument functions (`shifu_cmd_argr`, `shifu_cmd_args`) can only be used in leaf commands.

The option and argument declaration order in a command function matters:
1. Help is generated in declaration order
1. Help strings from parent commands' deferred options are similarly deferred to the end of the generated help string
1. Positional arguments are parsed in declaration order
1. Options must be declared before any positional arguments, and positional arguments before remaining arguments

### Completion functions

#### `shifu_cmd_cpte`
* Enumeration completion
* Static list of tab completions for the preceding option or argument
* Example
  ```sh
  shifu_cmd_cpte debug info warn error
  ```

#### `shifu_cmd_cptf`
* Function completion
* Function to dynamically generate tab completions for the preceding option or argument
* The function should call [`shifu_add_cpts`](#shifu_add_cpts) to register completions
* Example
  ```sh
  shifu_cmd_cptf file_ext_completions

  file_ext_completions() {
    shifu_add_cpts "$(ls -1 | sed 's/.*\.//' | sort -u)"
  }
  ```

#### `shifu_cmd_cptp`
* Path completion
* Enable path completions for the preceding option or argument
* Takes a required mode argument:
  * `:files:` - complete files and directories
  * `:dirs:` - complete directories only. Note: in zsh, after navigating into a directory with no subdirectories, the completion system falls back to showing files. This is standard zsh behavior and differs from bash, which strictly shows only directories.
  * `:glob: "pattern"` - complete files matching a glob pattern
* Examples
  ```sh
  shifu_cmd_cptp :files:
  shifu_cmd_cptp :dirs:
  shifu_cmd_cptp :glob: "*.txt"
  ```

### Configuration

Shifu has a few variables that can be set after sourcing to change default behavior. Typically they are set just before calling `shifu_run`.

#### `shifu_allow_options_anywhere`
* Controls whether arguments starting with a dash are treated as errors
* Type: bool
  * `false`: options (arguments starting with `-`) are not allowed after positional arguments, shifu will error if it encounters one
  * `true`: allows positional and remaining arguments that begin with a dash. Useful if flags need to be passed through cli arguments
* Default: `false`
* Example
  ```sh
  shifu_allow_options_anywhere=true
  ```

#### `shifu_complete_single_dash_options`
* Controls tab completion behavior when current word is a single `-`
* Type: bool
  * `false`, completing `-` only shows long options (`--option-name`)
  * `true`, completing `-` shows both short (`-o`) and long (`--option-name`) options
* Default: `false`
* Example
  ```sh
  shifu_complete_single_dash_options=true
  ```

#### `shifu_help_flags`
* Space-separated list of flags that trigger help output, override to change which flags show help
* Type: string
* Default: `"-h --help"`
* Example
  ```sh
  shifu_help_flags="--help"
  ```

### Miscellaneous

#### `shifu_add_cpts`
* Registers one or more strings to add as completions
* Must only be called within functions passed to `shifu_cmd_cptf`
* Example
  ```sh
  dynamic_completions() {
    shifu_add_cpts "$(func_to_get_completions)"
  }
  ```

#### `shifu_less`
* Creates shorthand aliases for all `shifu_cmd_*` functions without the `shifu_` prefix (aka `cmd_name` instead of `shifu_cmd_name`)
* Called after sourcing shifu, typically on the same line
* Makes command definitions less verbose, but the shorter names are more likely to collide with functions in your script
* Example
  ```sh
  . "${0%/*}"/shifu && shifu_less || exit 1

  cli_cmd() {
    cmd_name cli
    cmd_optd -o -- OPTION default "An option"
    cmd_func cli_func
  }
  ```
