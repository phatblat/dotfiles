function shell_choose \
    --description='Interactive prompting for choosing a new default shell.'

    set -l shells bash zsh fish
    set -l current_shell (basename $SHELL)

    echo "Your default shell is $current_shell, would you like to change it?"

    # Input
    read \
        --prompt-str "New shell ($shells): " \
        --local new_shell

    if test $new_shell = $current_shell
        echo "No changes."
        return 1
    end

    set -l brew_binaries (brew_home)/bin
    set -l new_shell_path $brew_binaries/$new_shell

    if ! grep -q $new_shell_path /etc/shells
        shell_add $new_shell
    end

    echo "Changing default shell to: $new_shell"
    shell_switch $new_shell
end
