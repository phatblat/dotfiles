# showgit_remote - Searches for .git repos recursively below the current dir, printing remote URL
export def showgit_remote [] {
    for git_dir in (showgit | lines) {
        let dir = ($git_dir | path dirname)
        print $dir
        ^grep url $"($dir)/.git/config"
    }
}
