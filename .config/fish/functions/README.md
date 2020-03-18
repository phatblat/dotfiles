# Custom Fish Functions

Here lie the `fc` (730+) custom, autoloaded fish shell functions that I've amassed over the years.
Some of these were converted from Bash functions/aliases, but a lot were first created after switching
to fish because it makes creating and maintaining them much easier.

## Style Guide

This is a WIP style guide which contains the conventions I'd _like_ to apply to all fish source code -
which is mostly functions - but doesn't mean all current code follows this style. As I edit functions
this style will be applied when there is a delta, but all new code will follow these guidelines.

### Function Names

Function names will be:

- lower case
- snake_case

### Layout

The first line of a function file should start with the `function` keyword,
followed by the function name. All other arguments to the `function` builtin
command should be wrapped onto separate lines, escaping the carriage return using a backslash (`\`)
character. Each line will be indented one level. Arugments should be specified
using the longer double-dash form for clarity (`--description` instead of `-d`).

#### Argument Ordering

The most common arguments should be specified first, followed by less commonly used arguments.

1. description
1. argument-names
1. wraps

### Indentation

4 spaces
