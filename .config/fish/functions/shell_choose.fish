# Interactive prompting for choosing a new default shell.
function shell_choose
    set -l shells bash zsh fish
    set -l current_shell (basename $SHELL)

    echo "Your default shell is $current_shell, would you like to change it?"

    get --prompt "New shell ($shells):" --default=$current_shell | read -l new_shell

    if test $new_shell != $current_shell
        echo "Changing default shell to: "$new_shell
        shell_switch $new_shell
    else
        echo "No changes."
    end
end
