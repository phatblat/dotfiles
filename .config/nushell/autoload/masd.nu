# Dependencies:
#   functions: clone_or_pull createdirs
#   builtins:  cd path join
#   externals: none

# Quick nav to mas-cli/mas repo (clone or pull, then cd in)
export def --env masd [] {
    let repo_url = "git@github.com:mas-cli/mas.git"
    let base_dir = ($env.HOME | path join "dev" "mas-cli")
    let local_dir = ($base_dir | path join "mas")

    createdirs $base_dir
    clone_or_pull $local_dir $repo_url
    cd $local_dir
}
