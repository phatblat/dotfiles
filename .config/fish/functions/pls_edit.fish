# Edits Powerline Shell configuration.
# https://github.com/banga/powerline-shell
function pls_edit
    set -l powerline_shell_dir ~/dev/vim/powerline-shell
    set -l configuration config.py
    set -l compile_script install.py
    set -l runtime_script powerline-shell.py

    pushd $powerline_shell_dir

    editw $configuration
    eval ./$compile_script
    and echo "Don't forget to commit changes to $powerline_shell_dir/$runtime_script"

    popd
end
