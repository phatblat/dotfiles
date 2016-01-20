#-------------------------------------------------------------------------------
#
# shell/editors.zsh
# Editor aliases
#
#-------------------------------------------------------------------------------

# edit
export VISUAL='/usr/local/bin/atom'
alias edit="${VISUAL}"

# e quick edit alias - with no args, opens editor to the current dir
function e {
  if [ -z "$1" ] ; then
    edit .
  else
    edit "$*"
  fi
}

# o quick open alias - with no args, opens finder to the current dir
function o {
  if [ -z "$1" ] ; then
    open .
  else
    # -t  Causes the given path to be opened with the default app, as determined via LaunchServices
    open -t "$*"
  fi
}

# Sublime symlink installation
alias subl_link='ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" ~/bin/subl'


#-------------------------------------------------------------------------------
# Profile
#-------------------------------------------------------------------------------
alias dotfiles="edit ~/.dotfiles"

# Prints out aliases containing the given substring
function explain {
  alias | grep $1

  # 'type' prints out what the given argument is, if found.
  # helpful for finding functions, which aren't included in the alias output
  output=$(type $1)
  if [[ $? -eq 0 ]]; then
    # Echo output on success
    echo ${output}
  fi
}


# TODO: Figure out how to prevent PATH from growing when reloadprofile is invoked
alias reloadprofile="source ~/.zshrc"
