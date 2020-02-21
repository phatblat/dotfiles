# Edit .config/omf/bundle to change packages
#
# Sequencing
# - After: brew (fish)
# - Requires Fish Shell
function 🐠_omf \
    --description='Updates oh-my-fish and bundled packages.'

    echo "🐠 oh-my-fish - https://github.com/oh-my-fish/oh-my-fish"
    echo

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

    # Install missing packages from .config/omf/bundle
    omf install

    echo "Installed plugins: "
    omf list
    omf doctor
end
