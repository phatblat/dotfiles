#
# justfile for build-infra
#
# export - Export all variables as environment variables.

set export := true

# ignore-comments - Ignore comments when formatting.

set ignore-comments := true

# script-interpreter - Command used to invoke recipes with empty [script] attribute.

set script-interpreter := ['bash', '-eu']

# unstable - Enable unstable features. Required for --fmt.

set unstable := true

#
# variables
#

true := 'true'
false := 'false'

# ANSI colors for formatting output

color_gray := '\e[90m'
color_green := '\e[32m'
color_red := '\e[31m'
color_reset := '\e[0m'

#
# aliass
#

alias fmt := format
alias ls := list

#
# info group recipes
#

# Default recipe, lists available recipes
[script]
_default:
    just --list

[group('info')]
@versions:
    mise --version

[group('info')]
@outdated:
    mise outdated --bump

#
# configuration group recipes
#

# Installs tools using mise
[group('configuration')]
@install:
    mise install

list:
    mise list --global

# Formats mise config and justfile
[group('configuration')]
@format:
    mise fmt
    just --fmt

#
# checks group recipes
#

# Checks justfile and ansible playbooks
[group('checks')]
lint:
    mise fmt --check
    just --fmt --check
