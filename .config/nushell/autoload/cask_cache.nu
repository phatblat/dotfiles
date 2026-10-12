# cask_cache - Manage the Homebrew Cask cache. Without args the contents of the cache are displayed.
export def cask_cache [command: string = "show"] {
    let cache_dir = ("~/Library/Caches/Homebrew/Cask" | path expand)
    match $command {
        "clean" => {
            ^trash -v $cache_dir
        }
        "show" => {
            print "Homebrew Cask cache is user-specific"
            ^ls -la -d $cache_dir
            ^ls -la $cache_dir
        }
        _ => {
            error make { msg: "Usage: cask_cache [clean|show]" }
        }
    }
}
