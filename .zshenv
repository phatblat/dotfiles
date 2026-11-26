# ~/.zshenv - the one zsh startup file that cannot move: zsh reads it from
# $HOME before anything else. It only redirects the rest of startup
# (.zshenv, .zprofile, .zshrc, .zlogin) to $ZDOTDIR under XDG_CONFIG_HOME.
# Normalize NO_COLOR: harnesses export NO_COLOR=1, but clap-parsed bool flags
# (e.g. ditto tracing-config --disable-color) require "true"/"false".
export NO_COLOR=true

# bash ignores zshenv; point its non-interactive startup at a normalizer.
export BASH_ENV="$HOME/.config/bash_env"

# Exported for every process zsh starts: LaunchAgents and `$SHELL -c` probes
# run `zsh -l -c`. Derived from HOME unconditionally so a HOME-remapped shell
# (wt shell, `just test`) points at its own .config, never the real one.
export XDG_CONFIG_HOME="$HOME/.config"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
. "$ZDOTDIR/.zshenv"
