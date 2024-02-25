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

# Cargo
source ~/.cargo/env

# Jebrains Toolbox App scripts
export PATH="$PATH:/Users/phatblat/Library/Application Support/JetBrains/Toolbox/scripts"

