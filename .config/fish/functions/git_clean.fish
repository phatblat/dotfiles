function git_clean \
    --description 'Clean non-tracked files from the working tree'
    if test $PWD = $HOME
        error Refusing to clean user home
        return 1
    end
    git clean -xffd
end
