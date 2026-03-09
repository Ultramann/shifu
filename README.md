<p align="center">
  <img src="./assets/banner-dark.svg#gh-dark-mode-only" width="65%">
  <img src="./assets/banner-light.svg#gh-light-mode-only" width="65%">
</p>

**SH**ell **I**nterface **F**ramework **U**tility, shifu, is a framework that makes creating powerful clis from shell scripts simple. Shifu has the following features:

* declarative argument parsing
* subcommand dispatch
* scoped help generation
* tab completion code generation for interactive shells
* implemented 100% in POSIX-compliant shell script
* compatibility with POSIX-based shells; tested with: 
  * ash, bash, dash, ksh, zsh

Shell scripts are great for gluing commands together. But when you need to make and maintain subcommands, with scoped options, and help strings, things can get messy fast. Shifu handles the cli boilerplate so you can focus on functionality.

## Table of contents

* [Installation](#installation)
* [Quickstart](#quickstart)
* [Subcommands](#subcommands)
* [Tab completion](#tab-completion)
* [FAQ](#faq)
* [API](#api)

## Installation

Since shifu is just a single POSIX-compatible script, all you need to do is get a copy of it and either put it in a location on your `PATH` or in the same directory as your cli script.

```sh
curl -O https://raw.githubusercontent.com/Ultramann/shifu/refs/heads/main/shifu
```

## Quickstart

Shifu revolves around the concept of a command. A command is a function, by convention ending in `_cmd`, that _only_ contains calls to shifu `cmd` or `cmp` functions. Shifu `cmd` and `cmp` functions provide a DSL which shifu uses to wire together your cli. Commands are passed to shifu's command runner, `shifu_run`, or referenced as subcommands.

Below is a very minimal, introduction shifu cli script.

[`examples/intro`](/examples/intro)

```sh
. "${0%/*}"/shifu || exit 1

intro_cmd() {
  shifu_cmd_name intro
  shifu_cmd_func intro_function
  shifu_cmd_help "An introduction shifu cli"
  shifu_cmd_long "This command function will invoke intro_function which prints an argument
provided by '-a' or '--arg' or none if no argument is provided"
  shifu_cmd_optd -a --arg -- ARG none "Example argument to echo"
}

intro_function() {
  echo "$ARG"
}

shifu_run intro_cmd "$@"
```

Calling this cli, we can see how it parses `-─a shifu` into the variable `ARG` when provided, and also automatically generates help strings.

```txt
$ examples/intro
none
$ examples/intro -a shifu
shifu
$ examples/intro --help
An introduction shifu cli

This command function will invoke intro_function which prints an argument
provided by '-a' or '--arg' or none if no argument is provided

Options
  -a, --arg [ARG]
    Example argument to echo
    Default: none
  -h, --help
    Show this help
```

The diagram below shows how shifu is connecting together this cli script to print the value `shifu` in `intro_function`.

```
       examples/intro -a shifu ──────────────┐ 
                  ▲    ▲                     │ 
                  │    └─────────────┐       │ 
                  └──────────┐       │       │ 
    intro_cmd() {            │       │       │ 
      shifu_cmd_name intro ──┘       │       │ 
┌──── shifu_cmd_func intro_function  │       │
│     shifu_cmd_optd -a --arg -- \ ──┘       │
│       ARG none "Example argument to echo"  │
│  }     ▲                                   │ 
│        └───────────────────────────────────┘ 
│                                             
└─► intro_function() {                        
      echo "$ARG"                             
    }     
```

## Subcommands

Shifu supports subcommands with scoped argument parsing and help generation. Use `shifu_cmd_subs` instead of `shifu_cmd_func` to reference subcommand, `_cmd`, functions by name. Options in non-leaf commands (those with `shifu_cmd_subs`) require a mode annotation — `:defer:` to inherit the option to subcommands, or `:eager:` to parse it locally before subcommand dispatch. Here's what the minimal structure of a subcommand cli looks like (a complete example can be found below):

```sh
root_cmd() {
  shifu_cmd_name root
  shifu_cmd_subs sub_cmd
}

# referenced by name in root_cmd -> shifu_cmd_subs
sub_cmd() {
  shifu_cmd_name sub
  shifu_cmd_func sub_func
}

# referenced by name in sub_cmd -> shifu_cmd_func
sub_func() {
  echo "Hello from sub_func"
}

shifu_run root_cmd "$@"
```

Invoking this script:

```txt
$ root sub
Hello from sub_func
```

Below is an example cli, [`examples/dispatch`](/examples/dispatch), with two subcommands, `hello` and `echo`, each with their own arguments.

![Quickstart](/assets/dispatch_demo.gif)

<details>

<summary><b>Source code</b></summary>

Note, this example calls `shifu_less` after sourcing `shifu` to provide a version of the `shifu_cmd` and `shifu_cmp` functions without the `shifu_` prefixes.

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
  cmd_optb :defer: -g --global -- GLOBAL false true "Global binary option"
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
  [ "$GLOBAL" = true ] && message="🌐 " || message=""
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
  echo "Global binary option: $GLOBAL"
  echo "Required option:      $REQUIRED"
  echo "Option w/ default:    $DEFAULT"
  echo "Positional argument:  $POSITIONAL"
}

# Run root command passing all script arguments
shifu_run dispatch_cmd "$@"
```

The diagram below shows how shifu is connecting together this cli script to print the value `🌐 Hello, World!` in `dispatch_hello`.

```
┌───────────── sets to ─────────────┐
│ ┌──────────── true ──────────────┐│
│ │                                ▼│
│ │        examples/dispatch hello -g --name World ─────────────────────┐
│ │                     ▲      ▲         ▲                              │
│ │                     │      │         └────────────────────────────┐ │
│ │                     │      └───────────────────────────────┐      │ │
│ │ dispatch_cmd() {    │              ┌─► hello_cmd() {       │      │ │
│ │   cmd_name dispatch ┘              │     cmd_name hello ───┘      │ │
│ │   cmd_subs hello_cmd echo_cmd ─────┘ ┌── cmd_func dispatch_hello  │ │
│ └── cmd_optb :defer: -g --global \ ┌───┘   cmd_optd -n --name \ ────┘ │
└────►  -- GLOBAL false true \       │ ┌──►    -- NAME "mysterious \    │
        "Global binary option"       │ │       user" "Name to greet"    │
    }                                │ │ }                              │
      ┌──────────────────────────────┘ └────────────────────────────────┘
      │
      └─► dispatch_hello() {
            [ "$GLOBAL" = true ] && message="🌐 " || message=""
            echo "${message}Hello, $NAME!"
          }
```

</details>

## Tab completion

Since shifu knows all about the structure of your cli it can generate tab completion code for interactive shells that support it, bash and zsh. 

By default, subcommand and option names can be tab completed. If you'd like to add tab completion for option values and positional/remaining arguments shifu provides three `cmp` functions
* `shifu_cmp_enum`: static list of completions
* `shifu_cmp_func`: function to generate list of completions. Completions are added with the shifu function `shifu_add_cmps`
* `shifu_cmp_path`: ties into your shell completion framework to enable easy path completions for directories and files

These functions can be called after an option or argument declaration to instruct shifu what the completions for the preceding argument value should be.

Below is an example cli, [`examples/tab`](/examples/tab), demonstrating tab completion capabilities.

![Tab completion](/assets/tab_demo.gif)

<details>

<summary><b>Source code</b></summary>

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
  cmp_enum magic value
  cmd_optd -f --func -- FUNC_COMP func_comp "Function completion, file extensions"
  cmp_func file_extension_completions
  cmd_argr              PATH_COMP "Path completion"
  cmp_path
}

file_extension_completions() {
  # dynamically complete with extensions from files in current directory
  shifu_add_cmps "$(ls -1 | grep '\.' | sed 's/.*\.//' | sort -u)"
}

demo_cmd() {
  cmd_name demo
  cmd_help "No-op command to show multiple subcommand completion options"
  cmd_func no_op
}

no_op() { :; }

shifu_run tab_cmd "$@"
```

If you'd like to test the tab completion from this example you can easily from a bash or zsh (requires autoloading `compinit`) terminal by running

```sh
export PATH="$PATH:$(pwd)/examples"
```

so your shell can find the example `tab` cli, and

```sh
eval "$(examples/tab --tab-completion bash)"
# or, choose for your shell
eval "$(examples/tab --tab-completion zsh)"
```

then tabbing along to the beat.

</details>

### Enable

1. Ensure your cli is in a directory on your shell's `PATH`
1. Ensure your cli has access to shifu; either by putting shifu in the same `PATH` directory as your cli or adding shifu to another `PATH` directory
1. If you're using zsh, ensure that you've loaded and run `compinit` before the following eval call in your zshrc file
1. Add the following line to your shell's rc file, replacing `<your-cli>` with the name of your cli and `<shell>` with a supported shell: bash or zsh
   ```sh
   eval "$(<your-cli> --tab-completion <shell>)"
   ```

These instructions can also be found by running
```sh
<your-cli> --tab-completion help
```

## FAQ

* Why? This isn't what shell scripts are for.
  * Fair. However, sometimes a shell is all you want to require your users to have while still enabling a sophisticated cli ux; shifu can help deal with the cli boilerplate in those situations and let you focus on real functionality
  * Plus. Consider the following quote

    > If you only do what you can do, then you will never be better than what you are.
    >
    > \- Master Shifu, Kung Fu Panda
    
    Shifu gives cli shell scripts the opportunity to be better than they are
  * Finally. I want to use something like shifu, maybe others do too

* How does shifu name its variables/functions, will they collide with those in my script?
  * Shifu takes special care to prefix all variables/functions with `shifu` or `_shifu`
  * Calling `shifu_less` after sourcing shifu will create versions of all the `cmd` and `cmp` functions without the `shifu` prefix. This makes command code less busy, but adds function names that are more likely to cause a collision with those in your script

* What's with the `. "${0%/*}"/shifu || exit 1`?
  * `.` is the POSIX source command - it executes a file in the current shell, making shifu's functions available to your script, akin to importing
  * `"${0%/*}"` is parameter expansion that strips the filename from `$0` (the script path), leaving just the directory. This lets your script find shifu relative to itself rather than relying on `PATH`
  * `|| exit 1` exits the script if sourcing fails (e.g., shifu not found), preventing cryptic errors later
  * If shifu is on your `PATH`, you can simply use `. shifu || exit 1`

## API

### Command runner

#### `shifu_run`
* Called at end of a cli script
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
* Added in help above the auto-generated help for the command arguments
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

| Type     | Function           | Declares                     |
|----------|--------------------|------------------------------|
| Option   | `shifu_cmd_optb`   | Binary option                |
| Option   | `shifu_cmd_optd`   | Option with default          |
| Option   | `shifu_cmd_optr`   | Required option              |
| Argument | `shifu_cmd_argr`   | Required positional argument |
| Argument | `shifu_cmd_args`   | Remaining arguments          |

Option functions (`shifu_cmd_optb`, `shifu_cmd_optd`, `shifu_cmd_optr`) parse flagged arguments into variables. They take one or more flags (e.g. `-v`, `--verbose`) before a required `--` separator, followed by parsing configuration. Argument functions (`shifu_cmd_argr`, `shifu_cmd_args`) parse positional arguments by order of declaration.

All option and argument functions accept a `variable` argument — the shell variable name that will be set when parsing, and a `help` string used in auto-generated help output.

In **leaf commands** (those using `shifu_cmd_func`), no mode prefix is needed:
```sh
shifu_cmd_optd -o --output -- OUTPUT "default" "Output file"
```

In **non-leaf commands** (those using `shifu_cmd_subs`), option functions require a mode as the first argument:
* `:defer:` — option specification and parsing is deferred until the leaf command options
* `:eager:` — option parsing is done eagerly, before subcommand dispatch

```sh
shifu_cmd_optb :defer: -v --verbose -- VERBOSE false true "Verbose output"
shifu_cmd_optd :eager: -c --config  -- CONFIG "default" "Config file"
```

Positional and remaining argument functions (`shifu_cmd_argr`, `shifu_cmd_args`) can only be used in leaf commands.

The option and argument declaration order in a command function matters:
1. Help is generated in declaration order
1. Positional arguments are parsed in declaration order
1. Options must be declared before any positional arguments, and positional arguments before remaining arguments

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

#### `shifu_cmd_optr`
* Required option
* Variable must be set with the option flag and a following argument, error if not provided
* Signature
  ```sh
  shifu_cmd_optr <flags> -- <variable> <help>
  ```
* Example
  ```sh
  shifu_cmd_optr -m --mode -- MODE "Operating mode"
  ```

#### `shifu_cmd_argr`
* Required positional argument
* Variable is set from the next unparsed argument
* Leaf commands only
* Signature
  ```sh
  shifu_cmd_argr <variable> <help>
  ```
* Example
  ```sh
  shifu_cmd_argr TARGET "Target to process"
  ```

#### `shifu_cmd_args`
* Remaining arguments
* Zero or more unparsed arguments passed to the target function via `$@`
* Leaf commands only
* Signature
  ```sh
  shifu_cmd_args <help>
  ```
* Example
  ```sh
  shifu_cmd_args "Additional arguments"
  ```

### Completion functions

#### `shifu_cmp_enum`
* Enumeration completion
* Static list of tab completions for the preceding option or argument
* Example
  ```sh
  shifu_cmp_enum debug info warn error
  ```

#### `shifu_cmp_func`
* Function completion
* Function to dynamically generate tab completions for the preceding option or argument
* The function should call `shifu_add_cmps` to register completions
* Example
  ```sh
  shifu_cmp_func file_ext_completions

  file_ext_completions() {
    shifu_add_cmps "$(ls -1 | sed 's/.*\.//' | sort -u)"
  }
  ```

#### `shifu_cmp_path`
* Path completion
* Enable path completions (directories and files) for the preceding option or argument
* Example
  ```sh
  shifu_cmp_path
  ```
