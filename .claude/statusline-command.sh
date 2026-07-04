#!/usr/bin/env bash
# Claude Code statusline, converted from the color PS1 in ~/.bashrc:
#   PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
#
# \u@\h  -> user@host (short hostname)
# \w     -> current dir, with $HOME collapsed to ~ (matches bash's \w behavior)
# \$     -> dropped (trailing prompt char is not useful in a statusline)

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
[ -z "$cwd" ] && cwd=$(pwd)
display_dir="${cwd/#$HOME/\~}"

user=$(whoami)
host=$(hostname -s)

printf '\033[01;32m%s@%s\033[00m:\033[01;34m%s\033[00m' "$user" "$host" "$display_dir"
