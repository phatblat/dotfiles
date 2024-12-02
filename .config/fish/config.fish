#
# ~/.config/fish/config.fish
# Dotfiles
#

# resource limits
ulimit --file-descriptor-count 4096

# Fish logo
if status is-interactive
    if type -q neofetch
        neofetch --config ~/.config/neofetch/config.conf
    else if type -q fish_logo
        fish_logo brblue cyan green
    end
end

# Variables
source ~/.config/fish/variables.fish

if type -q direnv
    # Directory-based variables
    eval (direnv hook fish)
end

# GUI and items requiring a user
if status is-interactive
    if command --query starship
        starship init fish | source
    end
    if command --query zoxide
        zoxide init fish | source
    end

    if command --query fzf
        # Set up fzf key bindings
        fzf --fish | source
        fzf_key_bindings
    end

    if type -q thefuck
        # The Fuck
        eval (thefuck --alias | tr \n ';')
    end

    # 1Password CLI plugin
    source ~/.config/op/plugins.sh
end

# Created by `pipx` on 2023-08-29 02:06:37
set PATH $PATH /Users/phatblat/.local/bin
