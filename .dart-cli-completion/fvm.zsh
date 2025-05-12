if type compdef &>/dev/null; then
  _fvm_completion () {
    local reply
    local si=$IFS

    IFS=$'
' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" fvm completion -- "${words[@]}"))
    IFS=$si

    if [[ -z "$reply" ]]; then
        _path_files
    else 
        _describe 'values' reply
    fi
  }
  compdef _fvm_completion fvm
fi
