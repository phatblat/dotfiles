#!/usr/bin/env zsh
#-------------------------------------------------------------------------------
#
# .zshrc
#
# Entry point for sourcing modularized zsh profile files.
# Any files ending in .zsh get loaded into the shell environment.
#   .dotfiles/topic/*.zsh
#
#-------------------------------------------------------------------------------

# user_home is derived from the .zshrc location so that this script
# can be tested on CI
user_home=$( cd "$( dirname "$0" 2>/dev/null )" && pwd )

pushd $user_home/.dotfiles > /dev/null # 2>&1

for dir in *
do
  # Skip files at root
  if [[ -f "$dir" ]]; then
    continue;
  fi

  # Check if $dir any files to process
  # if [[ ! -f "$dir/*.zsh" ]]; then
  #     continue;
  # fi
  if stat -t $dir/*.zsh >/dev/null 2>&1
  then
      # echo found
  else
      continue;
  fi

  pushd "$dir" > /dev/null 2>&1

  # TODO: Log files at debug level
  # ls *.zsh

  for file in *.zsh
  do
    # Ensure $file is not a directory
    if [[ -f "$file" ]]; then
      source "$file"
    fi
  done

  popd > /dev/null 2>&1
done

popd > /dev/null 2>&1

