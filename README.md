```
/ ___)( )__( )(_   _)( ____)(  )(  )
\___ \|  __  | _) (_ | ___) | (__) | 
(____/(_)  (_)(_____)(_)    (______)
```

SHell Interface Function Utiltities, or shifu, is a set of utility functions to make creating a cli from a shell script simple. Shell scripts make gluing together functionality very easy and fairly portable. However, if you want to extend the functionality to have a cli like interface: have related but distinct entry points, nested subcommands, parse many command line options, or write and maintain documentation, shell languages can quickly turn from helpful glue to a messy kindergarden project: cute, but mostly useless. Shifu aims to address that problem and make creating a cli interface from a shell script declarative and mainable.

Shifu has the following qualities:
* POSIX compliance, aka compatibility many shells
  * tested with: ksh, dash, bash, zsh
* declarative argument parsing
* subcommand dispatching
* scoped help string generation

Some people may say that this is not what shells are for; and perhaps they're right. However, sometimes a shell is all you want to require your users to need while still enabling a sophisticated cli ux; shifu can help deal with the cli boilerplate in those situations and let you focus on the real functionality. Plus, consider the following quote.

> If you only do what you can do, then you will never be better than what you are.
>
> \- Master Shifu, Kung Fu Panda

Shifu gives cli shell scripts the opportunity to be better than they are.

## Quickstart

Shifu revolves around the concept of a command. A command is a function, by convention ending in `_cmd`, that _only_ calls shifu functions. These functions provide a declarative way to tell shifu how to wire together your cli. Commands are passed to one of shifu's command runners: `shifu_parse_args` and `shifu_run_cmd`.

Let's take a look at some toy scripts to get an introduction to writing shifu commands.

1. [Argument parsing](#argument-parsing)
2. [Subcommand dispatch](#subcommand-dispatch)
3. [Help generation](#help-generation)

### Argument parsing

With shifu, arguments to be parsed are declared with the function `shifu_cmd_arg`. The patterns to match against are provided before a `--`, followed by the variable which the argument will be parsed into and some information about defaults and help.

The command containing `shifu_cmd_arg` declarations is passed to the `shifu_parse_args` command runner along with all the positional arguments, `$@`. After `shifu_parse_args` runs the variables declared after `--` in the `shifu_cmd_arg` declarations will be populated depending on the arguments.

The following example demonstrates how to use the `shifu_cmd_arg` and `shifu_parse_args`.

[`examples/kfp-parse`](/examples/kfp-parse)

```sh
#! /bin/sh

# 1. Source shifu
. "$(dirname "$0")"/shifu || exit 1

# 2. Define command
kfp_parse_cmd() {
  shifu_cmd_arg -l --loud  -- LOUD      false true "Perform action loudly!"
  shifu_cmd_arg -q --quiet -- QUIET     false true "Try to perform action quietly."
  shifu_cmd_arg            -- CHARACTER "Select character to see quote: oogway, shifu, po."
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
1. Source the shifu...source
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

# 1. Source shifu
. "$(dirname "$0")"/shifu || exit 1

# 2. Declare a root command
kfp_dispatch_cmd() {
  # 3. Name the command
  shifu_cmd_name kfp-dispatch
  # 4. Declare subcommands to dispatch to
  shifu_cmd_subs quote_cmd advice_cmd

  # 5. Declare global arguments
  shifu_cmd_arg -l --loud  -- LOUD  false true "Perform action loudly!"
  shifu_cmd_arg -q --quiet -- QUIET false true "Try to perform action quietly."
}

# 6. Declare the shifu subcommand functions
quote_cmd() {
  # Declare the subcommand name
  shifu_cmd_name quote
  # 7. Declare the function to dispatch to
  shifu_cmd_func kfp_quote

  shifu_cmd_arg -- CHARACTER "Select character to see quote: oogway, shifu, po."
}

advice_cmd() {
  shifu_cmd_name advice
  shifu_cmd_func kfp_advice

  shifu_cmd_arg -- CHARACTER "Select character to see quote: oogway, shifu, po."
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
1. Source the shifu...source
2. Define a root shifu command, `kfp_dispatch_cmd`
3. Declare a name for the root command with `shifu_cmd_name`. By convention, the root command name should match the script name
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

## Installation

## API

### Command runners

### Command functions

#### `shifu_arg`
