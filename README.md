```
/ ___)( )__( )(_   _)( ____)(  )(  )
\___ \|  __  | _) (_ | ___) | (__) | 
(____/(_)  (_)(_____)(_)    (______)
```

SHell Interface Function Utilities, or shifu, is a set of utility functions to make creating a cli from a shell script simple. Shell scripts make gluing together functionality from different cli's easy and fairly portable. However, if you want to extend the capabilities to have cli like features: related but distinct entry points, nested subcommands, parse many command line options, or write and maintain documentation; shell languages can quickly turn from helpful glue to a messy kindergarten project: cute, but with value that's mostly of the sentimental variety. Shifu aims to address that problem and make creating a cli from a shell script declarative and maintainable.

Shifu has the following qualities:
* POSIX compliance; aka, compatibility many shells
  * tested with: ksh, dash, bash, zsh
* declarative argument parsing
* subcommand dispatching
* scoped help generation

Some people may say that this is not what shells are for; and perhaps they're right. However, sometimes a shell is all you want to require your users to need while still enabling a sophisticated cli ux; shifu can help deal with the cli boilerplate in those situations and let you focus on the real functionality. Plus, consider the following quote.

> If you only do what you can do, then you will never be better than what you are.
>
> \- Master Shifu, Kung Fu Panda

Shifu gives cli shell scripts the opportunity to be better than they are.

## Table of contents
* [Quickstart](#quickstart)
   * [Argument parsing](#argument-parsing)
   * [Subcommand dispatch](#subcommand-dispatch)
   * [Help generation](#help-generation)
* [Installation](#installation)
* [Import](#import)
* [FAQ](#faq)
* [API](#api)

## Quickstart

Shifu revolves around the concept of a command. A command is a function, by convention ending in `_cmd`, that _only_ calls shifu functions. These functions provide a declarative way to tell shifu how to wire together your cli. Commands are passed to one of shifu's command runners: `shifu_parse_args` and `shifu_run_cmd`.

Let's take a look at some toy scripts to get an introduction to writing and using shifu commands.

1. [Argument parsing](#argument-parsing)
2. [Subcommand dispatch](#subcommand-dispatch)
3. [Help generation](#help-generation)

### Argument parsing

With shifu, arguments to be parsed are declared with the function `shifu_cmd_arg`. The patterns to match against are provided before a `--`, followed by the variable which the argument will be parsed into and some information about defaults and help.

The command containing `shifu_cmd_arg` declarations is passed to the `shifu_parse_args` command runner along with all the positional arguments, `$@`. After `shifu_parse_args` runs the variables declared after `--` in the `shifu_cmd_arg` will be populated depending on the arguments.

The following example demonstrates how to use the `shifu_cmd_arg` and `shifu_parse_args` functions.

[`examples/kfp-parse`](/examples/kfp-parse)

```sh
#! /bin/sh

# 1. Source, import, shifu
. "$(dirname "$0")"/shifu || exit 1

# 2. Define command
kfp_parse_cmd() {
  shifu_cmd_arg -l --loud  -- LOUD  false true "Display text loudly!"
  shifu_cmd_arg -q --quiet -- QUIET false true 'Display text "quietly"'
  shifu_cmd_arg            -- CHARACTER "Select character to see quote: oogway, shifu, po"
}

# 3. Parse arguments with command
shifu_parse_args kfp_parse_cmd "$@"

# 4. Script things
case "$CHARACTER" in
  oogway) string="One often meets his destiny on the road he takes to avoid it." ;;
  shifu) string="There is now a level zero." ;;
  po) string="I love kung fuuuuuu!!!" ;;
  *) echo "Unknown option $1"; exit 1 ;;
esac

[ "$LOUD" = true ] && string=$(echo "$string" | awk '{ print toupper($0) }')
[ "$QUIET" = true ] && string="$string shhhh!!"
echo "$string"
```

Let's walk through the steps outlined in comments.
1. Import shifu by sourcing its...source
2. Define a shifu command, `kfp_parse_cmd`. As you can see, the `shifu_cmd_arg` function enables declaration of argument for shifu to parse and store in variables, `LOUD`, `QUIET`, and `CHARACTER`. This example uses two of the ways arguments can be declared, binary options and positional arguments; there are a few more though, see the api section on [`shifu_cmd_arg`](#shifu_cmd_arg) for more information
3. Parse arguments with `shifu_parse_args`. This command runner takes a command, here `kfp_parse_cmd`, and all the arguments, `"$@"` (it's good practice to include quotes). When `shifu_parse_args` runs, the `shifu_cmd_arg` usages in `kfp_parse_cmd` will parse the arguments in `$@` to values in the variables `LOUD`, `QUIET`, and `CHARACTER`
4. Do useful script things

Running this script with some different arguments will help clarify what's going on.

```txt
$ examples/kfp-parse oogway
One often meets his destiny on the road he takes to avoid it.
$ examples/kfp-parse -q shifu
There is now a level zero. shhhh!!
$ examples/kfp-parse --loud po
I LOVE KUNG FUUUUUU!!!
```

### Subcommand dispatch

Shifu manages subcommand dispatch with a trio of functions:
* `shifu_cmd_name`: the name to match against an argument
* `shifu_cmd_subs`: the names of possible shifu subcommands that could be dispatched to
* `shifu_cmd_func`: the function to call if the subcommand is dispatched to

Invoking subcommand dispatch is done with the `shifu_run_cmd` function. As with all command runners, `shifu_run_cmd` is passed the name of a shifu command function and all of the arguments `$@`.

The following example demonstrates how to use the shifu subcommand dispatch functions and `shifu_run_cmd`. This example builds on the previous as it also uses `shifu_parse_args` to parse the arguments passed to the functions that get dispatched to; it will also introduce another way `shifu_cmd_arg` behaves when used in a dispatching command. Much of the main logic from the previous example is used again, but this time extra functionality is added via dispatching.

[`examples/kfp-dispatch`](/examples/kfp-dispatch)

```sh
# /bin/sh

# 1. Source, import, shifu
. "$(dirname "$0")"/shifu || exit 1

# 2. Declare a root command
kfp_dispatch_cmd() {
  # 3. Name the command
  shifu_cmd_name kfp-dispatch
  # 4. Declare subcommands to dispatch to
  shifu_cmd_subs quote_cmd advice_cmd

  # 5. Declare global arguments
  shifu_cmd_arg -l --loud  -- LOUD  false true "Display text loudly!"
  shifu_cmd_arg -q --quiet -- QUIET false true 'Display text "quietly"'
}

# 6. Declare the shifu subcommand functions
quote_cmd() {
  # Declare the subcommand name
  shifu_cmd_name quote
  # 7. Declare the function to dispatch to
  shifu_cmd_func kfp_quote

  shifu_cmd_arg -- CHARACTER "Select character to see quote: oogway, shifu, po"
}

advice_cmd() {
  shifu_cmd_name advice
  shifu_cmd_func kfp_advice

  shifu_cmd_arg -- CHARACTER "Select character to see quote: oogway, shifu, po"
}

# 8. Declare the function called by the shifu subcommand
kfp_quote() {
  # 9. Parse the arguments passed to this function
  shifu_parse_args quote_cmd "$@"

  case "$CHARACTER" in
    oogway) string="One often meets his destiny on the road he takes to avoid it." ;;
    shifu) string="There is now a level zero." ;;
    po) string="I love kung fuuuuuu!!!" ;;
    *) echo "Unknown option $1"; exit 1 ;;
  esac

  [ "$LOUD" = true ] && string=$(echo "$string" | awk '{ print toupper($0) }')
  [ "$QUIET" = true ] && string="$string shhhh!!"
  echo "$string"
}

kfp_advice() {
  shifu_parse_args advice_cmd "$@"

  case "$CHARACTER" in
    oogway) string="Noodles; don't noodles. You are too focused on what was and what will be." ;;
    shifu) string="Anything is possible when you have inner peace." ;;
    po) string="You have to believe in yourself. That's the secret." ;;
    *) echo "Unknown option $1"; exit 1 ;;
  esac

  [ "$LOUD" = true ] && string=$(echo "$string" | awk '{ print toupper($0) }')
  [ "$QUIET" = true ] && string="$string shhhh!!"
  echo "$string"
}

# 10. Parse arguments with command
shifu_run_cmd kfp_dispatch_cmd "$@"
```

Let's walk through the steps outlined in comments.
1. Import shifu by sourcing its...source
2. Define a root shifu command, `kfp_dispatch_cmd`
3. Declare a name for the root command with `shifu_cmd_name`. This isn't technically required, but convention is to make it the name of the script
4. Declare subcommands for dispatch with `shifu_cmd_subs`. This function takes > 0 arguments, the names of subcommand command functions
5. Declare global arguments with `shifu_cmd_arg`. When `shifu_cmd_arg` is used in a dispatch function, all subcommands will inherit the argument parsing configuration. Here we declare two global arguments, `LOUD` and `QUIET`, so they can be reused in both subcommands
6. Define subcommands, this looks just like defining a command, as in set 3. You'll notice that these are the commands we passed to `shifu_cmd_subs` in step 4. As with any command, we can declare arguments; here we declare a positional argument, `CHARACTER` (global positional arguments are not allowed so we repeat this argument declaration in both commands)
7.  Instead of dispatching to subcommands with `shifu_cmd_subs`, these subcommands use `shifu_cmd_func` to dispatch to a function.
8. Write the functions dispatched to by the subcommands, aka referenced by `shifu_cmd_func` in step 7
9. Functions that are dispatched to are passed all the command line arguments that aren't used to determine the function dispatched to; so we use `shifu_parse_args` just like we did in the previous example, passing the name of the command function with argument declarations and all the arguments `"$@"`. The remaining logic use all the arguments that get parsed, both global, from step 5, and from this subcommand, from step 7. Note, the logic in `kfp_quote` is the same as that in the first example
10. Start command dispatch with the command runner `shifu_run_cmd` passing it the root command from step 2, and all the script arguments `"$@"`

Running this script with some different arguments will help clarify what's going on.

```txt
$ examples/kfp-dispatch advice oogway
Noodles; don't noodles. You are too focused on what was and what will be.
$ examples/kfp-dispatch advice -q shifu
Anything is possible when you have inner peace. shhhh!!
$ examples/kfp-dispatch quote --loud po
I LOVE KUNG FUUUUUU!!!
```

### Help generation

Since shifu knows everything about the structure of your cli it also provides functions to enable generation of scoped help strings. We've already seen some cases where help information has been provided to shifu functions, the last argument to `shifu_cmd_arg` is always a help string. Two more functions enable adding terse and long help information to shifu's auto-generated help strings:
* `shifu_cmd_help`: string to add at top of help string for command, and in subcommand section of parent command
* `shifu_cmd_long`: string to add after `shifu_cmd_help` string, only in command help

Shifu automatically parses the arguments `-h` and `--help` and uses all the information in help strings passed to the command functions to generate a comprehensive help string.

The follow code shows modified command functions from the subcommand dispatch example above, this time including more help information.

[`examples/kfp-help`](/examples/kfp-help)

```sh
# /bin/sh

. "$(dirname "$0")"/shifu || exit 1

kfp_help_cmd() {
  shifu_cmd_name kfp-help
  shifu_cmd_help "The kfp-dispatch example with help information included"
  shifu_cmd_long "An example shifu cli that provides toy functionality to see different Kung Fu Panda quotes"
  shifu_cmd_subs quote_cmd advice_cmd

  shifu_cmd_arg -l --loud  -- LOUD  false true "Display text loudly!"
  shifu_cmd_arg -q --quiet -- QUIET false true 'Display text "quietly"'
}

quote_cmd() {
  shifu_cmd_name quote
  shifu_cmd_help "Show quote from different Kung Fu Panda characters"
  shifu_cmd_long "This long help will be shown when getting help for this specific subcommand, but not shown when getting help for the parent command"
  shifu_cmd_func kfp_quote

  shifu_cmd_arg -- CHARACTER "Select character to see quote: oogway, shifu, po"
}

advice_cmd() {
  shifu_cmd_name advice
  shifu_cmd_help "Show advice from different Kung Fu Panda characters"
  shifu_cmd_long "Gosh, this movie has lots of amazing quotes"
  shifu_cmd_func kfp_advice

  shifu_cmd_arg -- CHARACTER "Select character to see quote: oogway, shifu, po"
}

# the rest is the same as in examples/kfp-dispatch until
shifu_run_cmd kfp_help_cmd "$@"
```

With these changes we'll get great help from our cli with `-h` or `--help`.

```txt
$ examples/kfp-help -h
The kfp-dispatch example with added help information

An example shifu cli that provides toy functionality to see different Kung Fu Panda quotes

Subcommands
  quote
    Show quote from different Kung Fu Panda characters
  advice
    Show advice from different Kung Fu Panda characters

Options
  -h, --help
    Show this help
```

Above we see that we asked for help on the root command and got back the terse and long help we included in our changes to `kfp_help_cmd`. We also see a subcommand section that includes the names of subcommands and their terse help. Note, even though we declared arguments in `kfp_help_cmd` -- for loud and quiet -- we don't see help for them here because `kfp_help_cmd` has no call to `shifu_cmd_func`; aka they can't be used here.

```txt
$ examples/kfp-help quote -h
Show quote from different Kung Fu Panda characters

This long help will be shown when getting help for this specific subcommand, but not shown when getting help for the parent command

Usage
  quote [OPTIONS] [CHARACTER]

Arguments
  CHARACTER
    Select character to see quote: oogway, shifu, po

Options
  -l, --loud
    Display text loudly!
    Default: false, set: true
  -q, --quiet
    Display text "quietly"
    Default: false, set: true
  -h, --help
    Show this help
```

Above we see that we asked for help on the quote subcommand and got back the terse and long help we included in our changes to `kfp_help_cmd`. Since `kfp_quote_cmd` has no subcommands, and instead has positional arguments we see some differences between it's help and the base help
* there's no subcommand section
* there are usage and arguments sections
* inherited options, for loud and quiet, are included

## Installation

Since shifu is just a POSIX compatible script all you need to do is get a copy of it.
```sh
curl -O https://raw.githubusercontent.com/ultramann/shifu/refs/heads/main/shifu
```

## Import
To "import" shifu you simply need to source its file path. If you've installed shifu to location on your path you can include the following at the top of your script.
```sh
. shifu
```

For a more portable method you can make sure shifu is in the same directory as the calling script and use the the following.
```sh
. "$(dirname "$0")"/shifu || exit 1
```

## FAQ
* What if I don't like to type/dislike seeing `shifu_` at the beginning of all the function calls?
  * No problem! You can just include `&& shifu_less` after you source shifu. This will define a version the API all without the `shifu_` prefix
  * You can see an example of this being used in [`examples/sgh`](/examples/sgh)

## API

### Command runners

#### `shifu_run_cmd`
* Takes the name of a command function, those ones that end in `_cmd` by convention, and all the arguments in the current scope, `$@`
* Dispatches call by parsing arguments in `$@` based on information in command function
* Will pass all unparsed arguments to function specified in in (sub)command's call to `shifu_cmd_func`
* Typical use, aka only use it was designed for, is as the last line of a script passing the root command function and all the arguments
* Example
  ```sh
  shifu_run_cmd root_cmd "$@"
  ```

#### `shifu_parse_args`
* Takes the name of a command function, those ones that end in `_cmd` by convention, and all the arguments in the current scope, `$@`
* Parses arguments to variables according to configuration declared in the command function
* Typical use is as the first line in the user function
* Example
  ```sh
  shifu_parse_args subcommand_one_cmd "$@"
  ```

### Command functions

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
  * Remaining arguments are retrieved by calling `eval "$shifu_align_args"` after `shifu_parse_args`

#### `shifu_cmd_larg`
* Local argument configuration
* Same purpose and usage as `shifu_cmd_larg` except subcommands do not inherit configuration
* Instead option arguments will be parsed greedily when parsing subcommand names allowing usage like
  ```sh
  cli root --local sub --args
  ```
