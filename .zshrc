#!/usr/bin/env zsh
#-------------------------------------------------------------------------------
#
# .zshrc
#
# Entry point for sourcing modularized zsh profile files.
# Any files ending in .zsh get loaded into the shell environment.
#   .dotfiles/<topic>/*.zsh
#
#-------------------------------------------------------------------------------

for file in ~/.dotfiles/**/*.zsh
do
  # Ensure $file is not a directory
  if [[ -f "$file" ]]; then
    echo $file
    source "$file"
  fi
done

echo ".dotfiles loaded"

### Added by the Bluemix CLI
source /usr/local/Bluemix/bx/zsh_autocomplete


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
