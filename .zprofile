#-------------------------------------------------------------------------------
#
# .zprofile
#
# .zprofile is for login shells. It is basically the same as .zlogin except that it's sourced before .zshrc whereas .zlogin is sourced after .zshrc. According to the zsh documentation, ".zprofile is meant as an alternative to .zlogin for ksh fans; the two are not intended to be used together, although this could certainly be done if desired."
#
# https://unix.stackexchange.com/questions/71253/what-should-shouldnt-go-in-zshenv-zshrc-zlogin-zprofile-zlogout/71258#71258
#
#-------------------------------------------------------------------------------

echo ".zprofile"

# Homebrew
export PATH="/opt/homebrew/bin:$PATH"
eval "$(brew shellenv)"

# FVM
export PATH="$HOME/fvm/default/bin:$PATH"

# Cargo
source $PATH/.cargo/env

# Jebrains Toolbox App scripts
export PATH="$PATH:$PATH/Library/Application Support/JetBrains/Toolbox/scripts"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source $PATH/.orbstack/shell/init.zsh 2>/dev/null || :

