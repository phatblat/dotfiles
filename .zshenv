# ~/.zshenv - the one zsh startup file that cannot move: zsh reads it from
# $HOME before anything else. It only redirects the rest of startup
# (.zshenv, .zprofile, .zshrc, .zlogin) to $ZDOTDIR under XDG_CONFIG_HOME.
# Normalize NO_COLOR: harnesses export NO_COLOR=1, but clap-parsed bool flags
# (e.g. ditto tracing-config --disable-color) require "true"/"false".
export NO_COLOR=true

# bash ignores zshenv; point its non-interactive startup at a normalizer.
export BASH_ENV="$HOME/.config/bash_env"

export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
. "$ZDOTDIR/.zshenv"
