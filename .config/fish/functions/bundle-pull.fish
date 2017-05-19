# Runs bundle-pull.rb ruby script
function bundle-pull
    # bundle exec ~/.dotfiles/git/bundle-pull.rb $argv

    # New logic

    # Ensure current dir is in a clean git repo
    if not git_inside_repo
        echo "This command must be run inside a git repo."
        return 1
    end

    if git_repo_dirty
        echo "The work tree is dirty, aborting."
        return 2
    end
end
