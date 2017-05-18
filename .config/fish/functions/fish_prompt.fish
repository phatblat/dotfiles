#
# ~/.config/fish/functions/fish_prompt.fish
# Dotfiles
#
# Displays the prompt using Powerline Shell.
# https://github.com/banga/powerline-shell
#

set -l powerline_shell_dir  ~/dev/vim/powerline-shell

function fish_prompt
    eval $powerline_shell_dir/powerline-shell.py $status --shell bare ^/dev/null
end
