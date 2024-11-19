# Edit .config/omf/bundle to change packages
#
# Sequencing
# - After: brew (fish)
# - Requires Fish Shell
function 🐠_omf \
    --description='Updates oh-my-fish and bundled packages.'

    echo "🐠 oh-my-fish - https://github.com/oh-my-fish/oh-my-fish"
    echo

    set -l repo_url git@github.com:oh-my-fish/oh-my-fish.git
    set -l base_dir ~/dev/shell/fish
    set -l local_dir $base_dir/oh-my-fish

    # Create parent directories
    createdirs $base_dir

    clone_or_pull $local_dir $repo_url

    # Install omf if necessary
    if not functions --query omf
        pushd $local_dir
        bin/install --offline
        # fish install --path=~/.local/share/omf --config=~/.config/omf
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
