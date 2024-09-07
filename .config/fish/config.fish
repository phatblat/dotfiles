#
# ~/.config/fish/config.fish
# Dotfiles
#

# resource limits
ulimit --file-descriptor-count 4096

# shell state debug logging
echo config.fish
if status is-login
    echo is-login
end
if status is-interactive
    echo is-interactive
end

# Disable the default welcome greeting
set --global --export fish_greeting

if is_mac
    # A lot of things check for XDG_CONFIG_HOME which isn't defined by default
    # on macOS. This may speed up scripts slightly.
    set --export --global XDG_CONFIG_HOME "$HOME/.config"

    if is_arm
        set --export --global BREW_HOME /opt/homebrew
    else
        set --export --global BREW_HOME /usr/local
    end
else if is_linux
    set --export --global BREW_HOME /home/linuxbrew/.linuxbrew
end

set --export --global --prepend --path PATH \
    /opt/homebrew/bin

# GUI and items requiring a user
if status is-interactive
    # warpify

    if type --query fastfetch
        fastfetch --config ~/.config/fastfetch/config.jsonc
    else if type --query fish_logo
        fish_logo
    end

    if command --query starship
        starship init fish | source
    end

    if command --query zoxide
        zoxide init fish | source
    end

    if type --query thefuck
        # The Fuck
        eval (thefuck --alias | tr \n ';')
    end
end


# Environment Variables - set once on login
# or set if bash was the login shell and fish was opened as a subshell.
if status is-login; or is_bash_login
    source ~/.config/fish/variables.fish

    if type --query direnv
        # Directory-based variables
        eval (direnv hook fish)
    end

    if type --query mise
        eval (mise activate fish)
        eval (mise hook-env --shell=fish)
    end
end
