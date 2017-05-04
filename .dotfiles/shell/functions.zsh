#-------------------------------------------------------------------------------
#
# shell/functions.zsh
# Miscellaneous command-line functions
#
#-------------------------------------------------------------------------------

lj info 'shell/functions.zsh'

# Shell Help
function bashman {
  man bash | less -p "^       $1 ";
}

# ctitle (custom title)
# Sets a descriptive title for the current Terminal tab. Given no args,
# the oh-my-zsh auto title behavior will be restored.
#
# NOTE: oh-my-zsh (loaded in antigen.zsh) manipulates the title using a precmd
# function called omz_termsupport_precmd. The DISABLE_AUTO_TITLE variable
# controls this behavior.
function ctitle {
  if [[ -z $1 ]]; then
    DISABLE_AUTO_TITLE="false"
    return 0
  fi
  
  # Disable OMZ auto-title so that it doesn't overwrite the custom title.
  DISABLE_AUTO_TITLE="true"
  echo -ne "\e]1;$@\a"
}

# Find
# usage: finds "search string" /base/dir
function finds {
  if [[ -z $1 ]]; then
    echo "Missing search term"
    echo 'usage: finds "search string" /base/dir'
    return 1
  fi
  glob="$1"

  base_dir="."
  if [[ -n "$2" ]]; then
    base_dir="$2"
  fi
  if [[ ! -a "${base_dir}" ]]; then
    echo "'${base_dir}' does not exist"
    return 2
  fi

  echo "glob: ${glob}"
  echo "base_dir: ${base_dir}"
  find "${base_dir}" -name "${glob}" -print
}

# bak
# Renames the first argument, either appending ".bak" or stripping that extension
# if already present.
# - $1 - The file or folder to rename
function bak {
  if [[ ! -a "$1" ]]; then
    echo "'$1' does not exist"
    return 1
  fi

  # > h
  # >      Remove a trailing pathname component, leaving the head.  This
  # >      works like `dirname'.
  # >
  # > r
  # >      Remove a filename extension of the form `.XXX', leaving the root
  # >      name.
  # >
  # > e
  # >      Remove all but the extension.
  # >
  # > t
  # >      Remove all leading pathname components, leaving the tail.  This
  # >      works like `basename'.
  # http://www.zsh.org/mla/users/2006/msg00239.html
  if [[ "${1:e}" == "bak" ]]; then
    # Remove the .bak extension
    mv "$1" "${1:r}"
    echo "Renamed to '${1:r}'"
  else
    # Append a .bak extension
    mv "$1" "$1.bak"
    echo "Renamed to '$1.bak'"
  fi
}
