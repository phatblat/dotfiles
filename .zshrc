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

# user_home is derived from  .zshrc location so that this script can be tested on CI
user_home=$( cd "$( dirname "$0" 2>/dev/null )" && pwd )

for file in ${user_home}/.dotfiles/**/*.zsh
do
  # Ensure $file is not a directory
  if [[ -f "$file" ]]; then
    # TODO: Log files at debug level
    echo $file
    source "$file"
  fi
done

echo ".dotfiles loaded"
