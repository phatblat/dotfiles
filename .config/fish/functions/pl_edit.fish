# Edits Powerline Shell configuration.
# https://github.com/banga/powerline-shell
function pl_edit
    set -l powerline_home $ADOTDIR/bundles/phatblat/powerline-shell-custom
    set -l configuration config.py
    set -l compile_script install.py
    set -l runtime_script powerline-shell.py

    pushd $powerline_home

    editw $configuration
    eval ./$compile_script

    git add $runtime_script

    popd
end
