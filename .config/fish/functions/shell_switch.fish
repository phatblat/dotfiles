# Changes the current $USER's shell using dscl. Outputs only the command to run for non-admins.
function shell_switch --argument-names new_shell
    if test -z $new_shell ^/dev/null
        echo "Usage: shell_switch bash|zsh|fish"
        return 1
    end

    set -l shell_path (brew --prefix)"/bin/$new_shell"
    set -l cmd "sudo dscl . -change $HOME UserShell $SHELL $shell_path"

    # Get the last path component
    set -l shell_last_path_component (basename $SHELL)
    if test $shell_last_path_component != $new_shell
        if user_is_admin
            eval $cmd

            echo -n "Changed "(dscl . -read $HOME UserShell)
            echo

            # Switch to new shell and prime the environment
            eval $shell_path
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
