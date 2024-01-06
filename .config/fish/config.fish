#
# ~/.config/fish/config.fish
# Dotfiles
#

# resource limits
ulimit --file-descriptor-count 4096

# Fish logo
if status is-interactive
    warpify

    if type --query neofetch
        neofetch --config ~/.config/neofetch/config.conf
    else if type --query fish_logo
        fish_logo
    end

    # if command --query oh-my-posh
    #     oh-my-posh init fish | source
    # end
    if command --query starship
        starship init fish | source
    end
end

# Variables
source ~/.config/fish/variables.fish

if type --query direnv
    # Directory-based variables
    eval (direnv hook fish)
end

if type --query mise
    eval "$(mise activate fish)"
    eval "$(mise hook-env --shell=fish)"
end

# GUI and items requiring a user
if status is-interactive
    # Set up RAM disk for Xcode DerivedData
    if is_phatmini
        # derived_data quiet
    end

    # Set up RAM disk for Cargo
    if is_phatmini
        # cargo_target quiet
    end

    if command --query zoxide
        zoxide init fish | source
    end

    # Use custom autoloaded functions
    # reload fish_mode_prompt
    # reload fish_right_prompt

    # Event Hooks
    # reload fish_postexec

    if type --query thefuck
        # The Fuck
        eval (thefuck --alias | tr \n ';')
    end
end
