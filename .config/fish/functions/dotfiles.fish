function dotfiles --description='Edit dotfiles.' \
        --argument-names=type
    set -l dotfiles ~/.dotfiles/
    set -l fishfiles ~/.config/fish/

    if test -z "$type"
        edit $dotfiles $fishfiles
        return
    end

    switch $type
        case . dot dotfiles
            edit $dotfiles
        case fish fishfiles
            edit $fishfiles
        case '*'
            echo "Usage: dotfiles [.|fish]"
            return 1
    end
end
