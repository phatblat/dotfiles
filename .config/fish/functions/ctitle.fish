# 
function ctitle
      if [[ -z $1 ]]; then
    DISABLE_AUTO_TITLE="false"
    return 0
  fi
  
  # Disable OMZ auto-title so that it doesn't overwrite the custom title.
  DISABLE_AUTO_TITLE="true"

  # echo -ne "\e]1;$@\a"

  #  print builtin works like echo, but gives us access to the % prompt escapes.
  # %n          expands to $USERNAME
  # %m          expands to hostname up to first '.'
  # %~          expands to directory, replacing $HOME with '~'
  print -Pn "\e]1;$@\a" $argv
end
