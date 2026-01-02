#
# ~/.config/fish/config.fish
# Dotfiles
#

set -gx MISE_PIN 1
set -gx ENABLE_LSP_TOOL 1

# resource limits
ulimit --file-descriptor-count 4096

# Fish logo
if status is-interactive
    if type -q fastfetch
        fastfetch
    else if type -q fish_logo
        fish_logo brblue cyan green
    end
end

# Variables
source ~/.config/fish/variables.fish

if type -q direnv
    # Directory-based variables
    # Use command substitution with timeout to prevent hangs
    set -l direnv_output (direnv hook fish 2>/dev/null)
    if test -n "$direnv_output"
        eval $direnv_output
    end
end

# GUI and items requiring a user
if status is-interactive
    if command --query starship
        # Only enable starship on desktop Warp (has WARP_IS_LOCAL_SHELL_SESSION)
        # Disables on iOS Warp where it hangs
        if set -q WARP_IS_LOCAL_SHELL_SESSION
            starship init fish | source
        end
    end
    if command --query zoxide
        zoxide init fish | source
    end

    if command --query fzf
        # Set up fzf key bindings
        fzf --fish | source
        # fzf_key_bindings is now handled by 'fzf --fish'
    end

    if type -q thefuck
        # The Fuck
        eval (thefuck --alias | tr \n ';')
    end

    # Warpify non-login shells that don' thave WARP_BOOTSTRAPPED defined.
    # TEMPORARILY DISABLED - may be causing hangs
    # if begin ! status is-login; and test -z "$WARP_BOOTSTRAPPED"; end
    #     warpify
    # end
end

# Add .local/bin to PATH
fish_add_path --prepend ~/.local/bin

# The next line updates PATH for the Google Cloud SDK.
if [ -f ~/dev/google-cloud-sdk/path.fish.inc ]
    . ~/dev/google-cloud-sdk/path.fish.inc
end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH ~/.cache/lm-studio/bin
# End of LM Studio CLI section


# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/phatblat/.cache/lm-studio/bin
# End of LM Studio CLI section

# mise activation for Go and other tools
mise activate fish | source

# Set mkcert CA root for Node.js if mkcert is available
if command --query mkcert
    set -x NODE_EXTRA_CA_CERTS (mkcert -CAROOT)/rootCA.pem
end
