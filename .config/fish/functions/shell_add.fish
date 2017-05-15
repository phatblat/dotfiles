# shell_add
function shell_add --argument-names new_shell
    if test -z $new_shell
        echo "Usage: shell_add new_shell"
        return 1
    end

    set -l system_shells_file /etc/shells
    set -l brew_binaries /usr/local/bin
    set -l new_shell_path $brew_binaries/$new_shell

    # Only care about Homebrew added shells.
    set -l system_shells (grep "^$brew_binaries" $system_shells_file)

    if not contains $new_shell $system_shells
        echo "Adding $new_shell_path to $system_shells_file"
        sudo echo $new_shell_path >> $system_shells_file
    else
        echo "$new_shell_path is already registered"
    end

    cat $system_shells_file
end
