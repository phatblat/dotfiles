#
# ~/.config/fish/functions/fish_prompt.fish
# Dotfiles
#
# Displays the prompt using Powerline Shell.
# https://github.com/banga/powerline-shell
#

set -l powerline_shell_dir ~/dev/vim/powerline-shell

# Don't overide stock fish_prompt unless Powerline is installed
if test -d $powerline_shell_dir
    function fish_prompt
        eval $powerline_shell_dir/powerline-shell.py $status --shell bare ^/dev/null
    end
end
