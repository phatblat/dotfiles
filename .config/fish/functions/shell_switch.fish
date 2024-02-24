function shell_switch \
    --argument-names new_shell \
    --description 'Changes the current $USER\'s shell using dscl. Outputs only the command to run for non-admins.'

    if test -z $new_shell 2>/dev/null
        echo "Usage: shell_switch bash|zsh|fish"
        return 1
    end

    set -l brew_binaries (brew_home)/bin
    set -l new_shell_path $brew_binaries/$new_shell

    if is_linux
        chsh --shell $new_shell_path
        return $status
    end

    set -l cmd "sudo dscl . -change $HOME UserShell $SHELL $new_shell_path"

    # Get the last path component
    set -l shell_last_path_component (basename $SHELL)
    if test $shell_last_path_component != $new_shell
        if user_is_admin
            eval $cmd

            echo -n "Changed "(dscl . -read $HOME UserShell)
            echo

            # Switch to new shell and prime the environment
            eval $new_shell_path
        else
            echo "Have an admin run the following command:"
            echo "    $cmd"
            return
        end
    else
        echo "No changes."
        return
    end
end
