```
/ ___)( )__( )(_   _)( ____)(  )(  )
\___ \|  __  | _) (_ | ___) | (__) | 
(____/(_)  (_)(_____)(_)    (______)
```

SHell Interface Function Utiltities, or shifu, is a set of utility functions to make creating a cli from a shell script simple. Shell scripts make gluing together functionality very easy and fairly portable. However, if you want to extend the functionality to have a cli like interface: have related but distinct entry points, nested subcommands, parse many command line options, or write and maintain documentation, shell languages can quickly turn from helpful glue to a messy kindergarden project: cute, but mostly useless. Shifu aims to address that problem and make creating a cli interface from a shell script declarative and mainable.

Shifu has the following qualities:
* POSIX compliance, aka compatibility many shells
  * tested with: ksh, dash, bash, zsh
* subcommand dispatching
* declarative argument parsing
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

[`examples/kfp-parse`](/examples/kfp-parse)

```sh
#! /bin/sh

# 1. Source shifu
. "$(dirname "$0")"/shifu || exit 1

# 2. Define command
kfp_parse_cmd() {
  shifu_arg -l --loud  -- LOUD      false true "Perform action loudly!"
  shifu_arg -q --quiet -- QUIET     false true "Try to perform action quietly."
  shifu_arg            -- CHARACTER "Select character to see quote: oogway, shifu, po."
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
2. Define a shifu command, `kfp_parse_cmd`. As you can see, the `shifu_arg` function enables declaration of argument for shifu to parse and store in variables, `LOUD`, `QUIET`, and `CHARACTER`. This example uses two of the ways arguments can be declared, binary options and positional arguments; there are a few more though, see the api section on [`shifu_arg`](#shifu_arg) for more information
3. Parse arguments with `shifu_parse_args`. This command runner takes a command, here `kfp_parse_cmd`, and all the arguments, `"$@"` (it's good practice to include quotes). When `shifu_parse_args` runs, the `shifu_arg` usages in `kfp_parse_cmd` will parse the arguments in `$@` to values in the variables `LOUD`, `QUIET`, and `CHARACTER`
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

### Help generation

## Installation

## API

### Command runners

### Command functions

#### `shifu_arg`
