#
# ~/.config/fish/functions/fish_prompt.fish
# Dotfiles
#

set ADOTDIR "$HOME/.antigen"
set POWERLINE_HOME "$ADOTDIR/bundles/phatblat/powerline-shell-custom"

function fish_prompt
    eval "$POWERLINE_HOME/powerline-shell.py $status --shell bare ^/dev/null"
end
