#
# justfile for ~phatblat
#
# export - Export all variables as environment variables.

set export := true

# ignore-comments - Ignore comments when formatting.

set ignore-comments := true

# script-interpreter - Command used to invoke recipes with empty [script] attribute.

set script-interpreter := ['bash', '-eu']
set quiet := true

# unstable - Enable unstable features. Required for --fmt.

set unstable := true

#
# variables
#
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
alias od := outdated
alias ub := usage-board
alias up := upgrade

#
# info group recipes
#

# Default recipe, lists available recipes
[script]
_default:
    just --list

# Lists installed tools managed by mise
[group('info')]
list:
    mise list --global

# Lists available upgrades
[group('info')]
outdated:
    mise outdated --bump

# Show Claude usage statistics
[group('info')]
usage:
    ccusage

# Show Claude usage statistics dashboard
[group('info')]
usage-board:
    ccusage blocks --live

#
# configuration group recipes
#

# Installs tools using mise
[group('configuration')]
install:
    mise install

# Upgrades tools using mise
[group('configuration')]
upgrade:
    mise upgrade --bump

# Formats mise config and justfile
[group('configuration')]
format:
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
