function dotfiles --description='Edit dotfiles.' \
        --argument-names=type
    set -l dotfiles ~/.dotfiles/
    set -l cronfiles ~/.dotfiles/cron/

    if test -z "$type"
        echo "Usage: dotfiles [.|cron|fish|git|powerline]"
        return 1
    end

    switch $type
        case . dot dotfiles
            edit $dotfiles
        case cron
            edit $cronfiles
        case '*'
            # Look for matching config dir
            if test -d ~/.config/$type
                edit ~/.config/$type
            else
                echo "Usage: dotfiles [.|cron|fish|git|powerline]"
                return 2
            end
    end
end
