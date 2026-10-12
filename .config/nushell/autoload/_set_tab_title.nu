# _set_tab_title - Set Warp tab title to git repo name or current directory
export def _set_tab_title [] {
    let repo = (do { ^git rev-parse --show-toplevel } | complete)
    let title = if $repo.exit_code == 0 {
        $repo.stdout | str trim | path basename
    } else {
        $env.PWD | path basename
    }
    print -n $"\u{001b}]0;($title)\u{0007}"
}
