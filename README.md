# shifu

SHell Interface Function Utiltities, or shifu, is a set of utility functions to make creating a cli from a shell script easy. Shell scripts make gluing together functionality very easy and fairly portable. However, if you want to extend the functionality to have a cli like interface: have related but distinct entry points, nested subcommands, parse many command line options, or write and maintain documentation, shell languages can quickly turn from helpful glue to a messy kindergarden project: cute, but mostly useless. And if you want make the script highly portable, read: POSIX compliant, so it's easy for anyone to use then you'll quickly encounter a lot of contradicting advice, difficulty testing, and limited available functionality.

Shifu has the following abilities/qualities:
* POSIX compliance
* subcommand dispatching
* declarative argument parsing
* scoped help string generation
* tab completion, for interactive shells (future)

Some people may say that this is not what shells are for; and perhaps they're right. However, sometimes a POSIX shell is all you want to require your users to need while still enabling a sophisticated cli ux; shifu can help deal with the cli boilerplate in those situations and let you focus on the real functionality. Plus, consider the following quote.

> If you only do what you can do, then you will never be better than what you are.
>
> \- Master Shifu, Kung Fu Panda

Shifu gives cli shell scripts the opportunity to be better than they are.

## Examples

## Installation

## API
