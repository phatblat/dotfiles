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

    set -l hostname (hostname)
    set -l remote_hostname
    switch $hostname
        case greymatter.local
            set remote_hostname imac.local
        case imac.local
            set remote_hostname greymatter.local
        case '*'
            echo "Unknown hostname: "$hostname
            return 3
    end

    set -l repo_path $PWD
    set -l current_branch (current-branch)
    set -l ssh_url "ssh://$USER@$remote_hostname:$repo_path"
end
