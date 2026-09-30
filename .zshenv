# ~/.zshenv - the one zsh startup file that cannot move: zsh reads it from
# $HOME before anything else. It only redirects the rest of startup
# (.zshenv, .zprofile, .zshrc, .zlogin) to $ZDOTDIR under XDG_CONFIG_HOME.
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
. "$ZDOTDIR/.zshenv"
