```
/ ___)( )__( )(_   _)( ____)(  )(  )
\___ \|  __  | _) (_ | ___) | (__) | 
(____/(_)  (_)(_____)(_)    (______)
```

**SH**ell **I**nterface **F**unction **U**tilities, or shifu, is a set of utility functions to make creating a cli from a shell script simple. Shell scripts make gluing together functionality from different cli's pretty easy. However, if you want to extend the a script's capabilities to have cli like features: related but distinct entry points, nested subcommands, parse many command line options, or write and maintain help strings; shell languages can quickly turn from helpful glue to a messy kindergarten project: cute, but with value that's mostly of the sentimental variety. Shifu aims to address that problem and make creating a cli from a shell script declarative and maintainable.

Shifu has the following qualities:
* POSIX compliance; aka, compatibility many shells
  * tested with: ksh, dash, bash, zsh
* declarative argument parsing
* subcommand dispatching
* scoped help generation

Some people may say that this is not what shell scripts are for; and perhaps they're right. However, sometimes a shell is all you want to require your users to need while still enabling a sophisticated cli ux; shifu can help deal with the cli boilerplate in those situations and let you focus on the real functionality. Plus, consider the following quote.

> If you only do what you can do, then you will never be better than what you are.
>
> \- Master Shifu, Kung Fu Panda

Shifu gives cli shell scripts the opportunity to be better than they are.

## Table of contents
* [Quickstart](#quickstart)
* [Installation](#installation)
* [Import](#import)
* [FAQ](#faq)
* [API](#api)

## Quickstart

Shifu revolves around the concept of a command. A command is a function, by convention ending in `_cmd`, that _only_ calls shifu `cmd` functions. These functions provide a declarative way to tell shifu how to wire together your cli. Commands are passed to one of shifu's command runner `shifu_run`, or referenced as subcommands. Note, this example calls `shifu_less` to provide a version of the shifu API without all the `shifu_` prefixes.

![Quickstart](/assets/demo.gif)

[`examples/quick`](/examples/quick)

```sh
#! /bin/sh

# Source, "import", shifu
. "$(dirname "$0")"/shifu && shifu_less || exit 1

# Write root command
quick_cmd() {
  # Name the command
  cmd_name quick
  # Add help for the command
  cmd_help "A quick shifu example"
  # Add long help for the command
  cmd_long "An example shifu cli demonstrating
  * subcommand dispatch
  * argument parsing
  * scoped help generation"
  # Add subcommands
  cmd_subs hello_cmd start_cmd
  # Add global argument
  cmd_arg -g --global -- GLOBAL false true "Global binary option"
}

# Write first subcommand, referenced in `cmd_subs` above
hello_cmd() {
  cmd_name hello
  cmd_help "A hello world subcommand"
  cmd_long "A subcommand that prints greeting with arguments"
  # Add command target function
  cmd_func hello
  # Add argument, will populate variable `NAME` when parsing cli args
  cmd_arg -n --name -- NAME "mysterious user" "Name to greet"
}

# Write first subcommand target function
hello() {
  # Use variable, `NAME`, populated by `cmd_arg` in `hello_cmd`
  echo "Hello, $NAME!"
}

# Write second subcommand, referenced in `cmd_subs` above
start_cmd() {
  cmd_name start
  cmd_help "A quick subcommand"
  cmd_long "A subcommand that prints results of parsed arguments"
  cmd_func start

  # Add argument, will populate variables when parsing cli args
  cmd_arg -d --default  -- W_DEFAULT  "default" "Example option w/ argument"
  cmd_arg -n --nullable -- WO_DEFAULT "Example option argument w/o default"
  cmd_arg               -- POSITIONAL "Example positional argument"
}

# Write second subcommand target function
start() {
  # Use variables populated by `cmd_arg` in `start_cmd` and `quick_cmd`
  echo "Global binary option: $GLOBAL"
  echo "Option w/ default:    $W_DEFAULT"
  echo "Option w/o default:   $WO_DEFAULT"
  echo "Postitional argument: $POSITIONAL"
}

# 9. Start root command passing all script arguments
shifu_run quick_cmd "$@"
```

## Installation

Since shifu is just a POSIX compatible script, all you need to do is get a copy of it.
```sh
curl -O https://raw.githubusercontent.com/ultramann/shifu/refs/heads/main/shifu
```

## Import
To "import" shifu you simply need to source its file path. If you've installed shifu to location on your path you can include the following at the top of your script.
```sh
. shifu
```

For a more portable method you can make sure shifu is in the same directory as the calling script and use the following.
```sh
. "$(dirname "$0")"/shifu || exit 1
```

## FAQ
* How does shifu name it's variables/functions, will they collide with those in my script?
  * Shifu takes special care to prefix any global variable/function with `shifu_` or `_shifu`
  * Calling `shifu_less` will create versions of all the [`cmd` functions](#cmd-functions) without the `shifu_` prefix. This makes command code more terse, but adds function names that are more likely to be collided with
  * All local varibles have any existing value saved and restored at the boundaries of the function using the variable

## API

### Command runner

#### `shifu_run`
* Takes the name of a command function, those ones that end in `_cmd` by convention, and all the arguments in the current scope, `$@`
* Dispatches call by parsing arguments in `$@` based on information in command function
* Will pass all unparsed arguments to function specified in in (sub)command's call to `shifu_cmd_func`
* Typical use, aka only use it was designed for, is as the last line of a script passing the root command function and all the arguments
* Example
  ```sh
  shifu_run root_cmd "$@"
  ```

### `cmd` functions

#### `shifu_cmd_name`
* Name used to reference command from command line arguments
* When the command is the root command, this name should match the name of the program
* When the command is a subcommand, the name is used to parse command line arguments
* Example
  ```sh
  shifu_cmd_name shifu
  ```

#### `shifu_cmd_subs`
* List of subcommand function names that can be routed to from command
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

#### `shifu_cmd_arg`
* Configuration to parse command line arguments to variable values
* If used in a command with subcommands, all descendent subcommands will inherit the configuration
* Arguments are passed in two parts separated by a required double dash, `--`:
  ```sh
  shifu_cmd_arg [matching patterns] -- [parsing configuration]
  ```
* Matching patterns are literal flag/option strings, e.g. `-v`, `--verbose`
  * Any number can be provided before the double dash
  ```sh
  shifu_cmd_arg -v --verbose -- ...
  ```
* Parsing configuration defines what values are stored when a pattern is matched or not
  * The first argument is the variable to store parsed value in
  * The last argument is always a help string
  * Different argument counts enable different parsing instructions

  | Kind               | Patterns | Variable | Default | Other     | Example                                    |
  |--------------------|----------|----------|---------|-----------|--------------------------------------------|
  | Option: binary     | > 0      | Yes      | Yes     | Set value | `-v -- VERBOSE false true "Binary option"` |
  | Option: w/ default | > 0      | Yes      | Yes     |           | `-o -- OUTPUT_DIR out "Option w/ default"` |
  | Option: no default | > 0      | Yes      | No      |           | `-l -- LOG_DIR "Option no default"`        |
  | Positional         | 0        | Yes      | No      |           | `-- CONFIG_FILE "Positional"`              |
  | Remaining          | 0        | No       | No      |           | `-- "Remaining"`                           |

* The order that multiple calls to `shifu_cmd_args` occurs in a command function matters in a few ways
  1. The help string generated from the arguments will match the order of the calls
  1. No options can be declared after any positional or remaining argument declaration
* Using `shifu_cmd_args` with the remaining argument combination does not actually parse command line arguments
  * The call only serves as a way to include help for remaining arguments

#### `shifu_cmd_larg`
* Local argument configuration
* Same purpose and usage as `shifu_cmd_larg` except subcommands do not inherit configuration
* Instead option arguments will be parsed greedily when parsing subcommand names allowing usage like
  ```sh
  cli root --local sub --args
  ```
