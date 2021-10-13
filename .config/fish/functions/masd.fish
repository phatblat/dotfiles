function masd \
    --description='Quick nav to mas dir'

    set -l repo_url git@github.com:mas-cli/mas.git
    set -l base_dir ~/dev/mas-cli
    set -l local_dir $base_dir/mas

    # Create parent directories
    createdirs $base_dir

    clone_or_pull $local_dir $repo_url

    nav $local_dir
end
