# Dependencies:
#   functions: none
#   builtins:  str trim split row last is-empty
#   externals: git

# Add a git remote; auto-builds a fork URL when only the remote name is given
export def ra [name: string, url?: string] {
    let remote_url = if ($url == null or ($url | is-empty)) {
        # Derive fork URL from the current upstream remote URL
        let upstream_branch = (try { ^git rev-parse --abbrev-ref HEAD@{u} | str trim } catch { "" })
        let upstream_remote = if ($upstream_branch | is-empty) { "origin" } else { $upstream_branch | split row "/" | first }
        let raw_url = (^git remote get-url $upstream_remote | str trim)
        # Drop scheme+host (everything up to and including the last ':')
        let path = ($raw_url | split row ":" | last)
        # Drop .git suffix
        let clean_path = ($path | str replace --regex '\\.git$' "")
        # Extract project name (last path component)
        let project = ($clean_path | split row "/" | last)
        $"git@github.com:($name)/($project).git"
    } else {
        $url
    }
    ^git remote add $name $remote_url
    ^git fetch $name
}
