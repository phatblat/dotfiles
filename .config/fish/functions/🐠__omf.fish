# Updates oh-my-fish and the plugins it manages. Installs if missing.
#
# Sequencing
# - After: brew (fish)
# - Requires Fish Shell
function 🐠__omf
    echo "🐠  oh-my-fish - https://github.com/oh-my-fish/oh-my-fish"
    echo

    set -l plugins \
        brew \
        nvm

    set -l themes none

    set -l omf_dir ~/dev/fish/oh-my-fish

    # Create parent directories
    createdirs ~/dev/fish

    clone_or_pull $omf_dir git@github.com:oh-my-fish/oh-my-fish.git

    # Install omf if necessary
    if not functions --query omf
        pushd $omf_dir
        bin/install --offline
        popd
    end


    # --------------------------------------------------------------------------
    #
    # Upstall
    #
    # --------------------------------------------------------------------------

    # Update omf and installed plugins
    omf update
    omf install

    echo "Installed plugins: "
    omf list
    omf doctor
end
