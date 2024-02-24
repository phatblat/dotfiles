function path_show \
    --description 'Pretty-prints the current PATH'
    echo fish_user_paths
    list $fish_user_paths
    echo
    echo PATH
    list $PATH
end
