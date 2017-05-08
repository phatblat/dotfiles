# 
function bak
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
  fi $argv
end
