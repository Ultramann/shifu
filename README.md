<p align="center">
  <img src="./assets/banner-dark.svg#gh-dark-mode-only" width="65%">
  <img src="./assets/banner-light.svg#gh-light-mode-only" width="65%">
</p>

**SH**ell **I**nterface **F**ramework **U**tility, or shifu, is a framework that makes creating a powerful cli from a shell script simple. Shifu has the following qualities:

* declarative argument parsing
* automatic subcommand dispatching
* scoped help generation
* tab completion code generation for interactive shells
* implemented 100% in POSIX-compliant shell script
* compatibility with POSIX based shells; tested with: 
  * bash, dash, ksh, zsh

Shell scripts make gluing together functionality from different command line programs pretty easy. However, if you want to extend the script's capabilities to have advanced cli features: related but distinct entry points, aka subcommands, nested subcommands, distinct command line options for those subcommands, subcommand specific help strings; shell languages can quickly turn from helpful glue to a messy kindergarten project: cute, but with value that's mostly of the sentimental variety. Shifu aims to address this difficulty and make creating a configurable and intuitive cli from a shell script declarative and maintainable.

## Table of contents

* [Quickstart](#quickstart)
* [Installation](#installation)
* [Import](#import)
* [Tab completion](#tab-completion)
* [FAQ](#faq)
* [API](#api)

## Quickstart

Shifu revolves around the concept of a command. A command is a function, by convention ending in `_cmd`, that _only_ contains calls shifu `cmd` functions. Shifu `cmd` functions provide a dsl which shifu uses to wire together your cli. Commands are passed to shifu's command runner, `shifu_run`, or referenced as subcommands.

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
  shifu_cmd_arg -a --arg -- ARG none "Example argument to echo"
}

intro_function() {
  echo "$ARG"
}

shifu_run intro_cmd "$@"
```

Calling this cli, we can see how it parses the argument we declare into the variable `ARG` and also automatically generates help strings.

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
    examples/intro -a shifu ────────────┐ 
               ▲    ▲                   │ 
               │    └────────────┐      │ 
               └─────────┐       │      │ 
intro_cmd() {            │       │      │ 
  shifu_cmd_name intro ──┘       │      │ 
  shifu_cmd_func intro_function  │      │ 
  shifu_cmd_arg -a --arg -- \ ───┘      │ 
    ARG none "Example argument to echo" │ 
}    ▲                                  │ 
     └──────────────────────────────────┘ 
```

Let's take a look at a more complicated example cli, [`examples/quick`](/examples/quick). This demo cli has two named subcommands, `hello` and `start`, each with their own arguments. First we'll see a gif interaction with the cli followed by the cli's annotated source.

![Quickstart](/assets/demo.gif)

<details>

<summary>Static Output</summary>

```txt
$ examples/quick -h
A quick shifu example

An example shifu cli demonstrating
  * subcommand dispatch
  * argument parsing
  * scoped help generation

Subcommands
  hello
    A hello world subcommand
  start
    A quick subcommand

Options
  -h, --help
    Show this help
$ examples/quick hello
Hello, mysterious user!
$ examples/quick hello -h
A hello world subcommand

A subcommand that prints greeting with arguments

Options
  -n, --name [NAME]
    Name to greet
    Default: mysterious user
  -g, --global
    Global binary option
    Default: false, set: true
  -h, --help
    Show this help
$ examples/quick hello -g -n World
🌐 Hello, World!


$ examples/quick start -h
A quick subcommand

A subcommand that prints results of parsed arguments

Usage
  start [OPTIONS] [POSITIONAL]

Arguments
  POSITIONAL
    Example positional argument

Options
  -d, --default [W_DEFAULT]
    Example option w/ argument
    Default: default
  -n, --nullable [WO_DEFAULT]
    Example option argument w/o default
  -g, --global
    Global binary option
    Default: false, set: true
  -h, --help
    Show this help
$ examples/quick start example
Global binary option: false
Option w/ default:    default
Option w/o default:   
Positional argument:  example
$ examples/quick start -g -d 'not default' \
> --nullable 'not null' example
Global binary option: true
Option w/ default:    not default
Option w/o default:   not null
Positional argument:  example
```

</details>

Note, this example calls `shifu less` to provide a version of the `shifu_cmd` functions without the `shifu_` prefixes.

[`examples/quick`](/examples/quick)

```sh
#! /bin/sh

# Source, "import", shifu
. "${0%/*}"/shifu less || exit 1

# Write root command
quick_cmd() {
  # Name the command
  cmd_name quick
  # Add subcommands
  cmd_subs hello_cmd start_cmd
  # Add help for the command
  cmd_help "A quick shifu example"
  # Add long help for the command
  cmd_long "An example shifu cli demonstrating
  * subcommand dispatch
  * argument parsing
  * scoped help generation"
  # Add global argument
  cmd_arg -g --global -- GLOBAL false true "Global binary option"
}

# Write first subcommand, referenced in `cmd_subs` above
hello_cmd() {
  cmd_name hello
  # Add target function
  cmd_func quick_hello
  cmd_help "A hello world subcommand"
  cmd_long "A subcommand that prints greeting with arguments"
  # Add argument, will populate variable `NAME` when parsing cli args
  # NAME defaults to 'mysterious user' if -n/--name aren't provided
  cmd_arg -n --name -- NAME "mysterious user" "Name to greet"
}

# Write first subcommand target function
quick_hello() {
  [ "$GLOBAL" = true ] && message="🌐 " || message=""
  echo "${message}Hello, $NAME!"
}

# Write second subcommand, referenced in `cmd_subs` above
start_cmd() {
  cmd_name start
  cmd_func quick_start
  cmd_help "A quick subcommand"
  cmd_long "A subcommand that prints results of parsed arguments"

  # Add argument, will populate variables when parsing cli args
  cmd_arg -d --default  -- W_DEFAULT  "default" "Example option w/ argument"
  cmd_arg -n --nullable -- WO_DEFAULT "Example option argument w/o default"
  cmd_arg               -- POSITIONAL "Example positional argument"
}

# Write second subcommand target function
quick_start() {
  # Use variables populated by `cmd_arg` in `start_cmd` and `quick_cmd`
  echo "Global binary option: $GLOBAL"
  echo "Option w/ default:    $W_DEFAULT"
  echo "Option w/o default:   $WO_DEFAULT"
  echo "Positional argument:  $POSITIONAL"
}

# Run root command passing all script arguments
shifu_run quick_cmd "$@"
```

The diagram below shows how shifu is connecting together this cli script to print the value `🌐 Hello, World!` in `quick_hello`.

```
┌─────────── sets to ─────────┐                                      
│ ┌────────── true ──────────┐│                                      
│ │                          ▼│                                      
│ │     examples/quick hello -g --name World ────────────────────────┐
│ │                ▲     ▲         ▲                                 │
│ │                │     │         └───────────────────────────────┐ │
│ │                └───┐ └───┐                                     │ │
│ │ quick_cmd() {      │     │         hello_cmd() {               │ │
│ │   cmd_name quick ──┘     └────────── cmd_name hello            │ │
│ │   cmd_subs start_cmd hello_cmd       cmd_func quick_hello      │ │
│ └── cmd_arg -g --global -- \           cmd_arg -n --name -- \ ───┘ │
└─────► GLOBAL false true \          ┌───► NAME "mysterious user" \  │
        "Global binary option"       │     "Name to greet"           │
    }                                │ }                             │
                                     └───────────────────────────────┘
```

## Installation

Since shifu is just a single POSIX compatible script, all you need to do is get a copy of it and either put it in a location on your `PATH` or in the same directory as your cli script.

```sh
curl -O https://raw.githubusercontent.com/Ultramann/shifu/refs/heads/main/shifu
```

## Import

To "import" shifu you simply need to source its file path. If you've installed shifu to location on your `PATH` you can include the following at the top of your script.

```sh
. shifu || exit 1
```

If you'd like not to assume that shifu is on the `PATH`, you can instead make sure shifu is in the same directory as the calling script and use the following.

```sh
. "${0%/*}"/shifu || exit 1
```

## Tab completion

Since shifu knows all about a cli's (sub)command names it can generate tab completion code for interactive shell's that support it, bash and zsh. 

1. Ensure your cli is in a directory on your shell's `PATH`
1. Ensure your cli has access to shifu; either by putting shifu in the same `PATH` directory as your cli or adding shifu to another `PATH` directory
1. If you're using zsh, ensure that you've loaded and run `compinit` before the following eval call in your zshrc file
1. Add the following line the your shell's rc file, replacing `<your-cli>` with the name of your cli and `<shell>` with a supported shell: bash or zsh
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
  * Shifu takes special care to prefix all variables/functions with `shifu_` or `_shifu_`
  * Importing shifu with the `less` argument will create versions of all the [`cmd` functions](#cmd-functions) without the `shifu_` prefix. This makes command code more terse, but adds function names that are more likely to cause a collision with those in your script

## API

### Command runner

#### `shifu_run`
* Called at end of a cli script
* Takes the name of a command function, those ones that end in `_cmd` by convention, and all script arguments, `"$@"`
* Dispatches call by parsing arguments in `"$@"` based on information in command function
* Parses arguments that match subcommand names until the subcommand specifies a function to call with `shifu_cmd_func`
* Parses all unparsed arguments into variables declared in `shifu_cmd_arg` calls
* Calls the function in `shifu_cmd_func` passing any still unparsed 
* Example
  ```sh
  shifu_run root_cmd "$@"
  ```

### `cmd` functions

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

#### `shifu_cmd_arg`
* Configuration to parse command line arguments to variables, optionally setting defaults for those variables
* Arguments are passed in two parts separated by a required double dash, `--`:
  ```sh
  shifu_cmd_arg [matching patterns] -- [parsing configuration]
  ```
* Matching patterns are literal flag/option strings, e.g. `-v`, `--verbose`
  * Any number can be provided before the double dash
    ```sh
    shifu_cmd_arg -v --verbose -- ...
    ```
* Parses arguments depending on patterns being provided and the number of arguments after the double dash
  | Kind               | Description/Structure/Example                           | 
  |--------------------|---------------------------------------------------------|
  | Binary option      | variable is assigned a value depending on whether or not the option is set |
  |                    | `[patterns] -- [variable] [default] [set value] "help"` |
  |                    | `-v --verbose -- VERBOSE false true "help"`             |
  | Option w/ default  | variable has a default value which can be overwritten with an option and following argument |
  |                    | `[patterns] -- [variable] [default] "help"`             |
  |                    | `-o --output -- OUTPUT "out" "help"`                    |
  | Option w/o default | variable can be set with an option and following argument, empty if unprovided |
  |                    | `[patterns] -- [variable] "help"`                       |
  |                    | `-t --temp -- TEMPORARY "help"`                         |
  | Positional         | variable set with required value from argument          |
  |                    | `           -- [variable] "help"`                       |
  |                    | `-- TEMPORARY "help"`                                   |
  | Remaining          | zero or more arguments passed to target function via "$@" |
  |                    | `           -- "help"`                                  |
  |                    | `-- "help"`                                             |

* The order that multiple calls to `shifu_cmd_arg` occurs in a command function matters in a few ways
  1. The help string generated from the arguments will match the order of the calls
  1. Positional arguments are parsed from the command line arguments in the order they are declared in the command function
  1. No options can be declared after any positional or remaining argument declaration
* If used in a command with subcommands, all descendent subcommands will inherit the configuration

#### `shifu_cmd_arg_loc`
* Local argument configuration
* Same purpose and usage as `shifu_cmd_arg_loc` except subcommands do not inherit configuration
* Instead option arguments will be parsed greedily when parsing subcommand names allowing usage like
  ```sh
  cli root --local sub --args
  ```
