function fishfiles --description='Edit fish dotfiles.'
    set -l fishfiles ~/.config/fish/
    edit $fishfiles
end
