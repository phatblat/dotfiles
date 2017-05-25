# Edit dotfiles.
function dotfiles
    set -l dotfiles ~/.dotfiles/
    set -l fishfiles ~/.config/fish/

    if test -z "$argv"
        edit $dotfiles $fishfiles
        return
    end

    switch $argv[1]
        case . dot dotfiles
            edit $dotfiles
        case fish fishfiles
            edit $fishfiles
        case '*'
            echo "Usage: dotfiles [.|fish]"
            return 1
    end
end
