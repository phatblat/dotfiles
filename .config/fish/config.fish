#
# ~/.config/fish/config.fish
# Dotfiles
#

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
    # Set up RAM disk for Xcode DerivedData
    if is_octodec; or is_phatmini
        derived_data quiet
    end

    # Set up RAM disk for Cargo
    if is_phatmini
        # cargo_target quiet
    end

    if command --query starship
        starship init fish | source
    end
    if command --query zoxide
        zoxide init fish | source
    end

    # Use custom autoloaded functions
    # reload fish_mode_prompt
    # reload fish_right_prompt

    # Event Hooks
    # reload fish_postexec

    if type -q thefuck
        # The Fuck
        eval (thefuck --alias | tr \n ';')
    end

    # 1Password CLI plugin
    source ~/.config/op/plugins.sh
end
