# Interactive prompting for choosing a new default shell.
function choose_shell
    set -l shells bash zsh fish
    set -l current_shell (basename $SHELL)

    echo "Your default shell is $current_shell, would you like to change it?"

    get --prompt "New shell ($shells):" --default=$current_shell | read -l new_shell

    if test $new_shell != $current_shell
        echo "Changing default shell to: "$new_shell
        switch_shell $new_shell
    else
        echo "No changes."
    end
end
