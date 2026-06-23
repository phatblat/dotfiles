# Dependencies:
#   functions: edit
#   builtins:  path join path exists is-empty
#   externals: none

# Open dotfiles or config subdirectories in the editor, dispatching by type argument
export def dotfiles [type?: string] {
    let dotfiles_dir = ($env.HOME | path join ".dotfiles")
    let cronfiles_dir = ($env.HOME | path join ".dotfiles" "cron")

    if ($type == null or ($type | is-empty)) {
        print "Usage: dotfiles [.|cron|fish|git|powerline]"
        return
    }

    match $type {
        "." | "dot" | "dotfiles" => { edit $dotfiles_dir }
        "cron" => { edit $cronfiles_dir }
        _ => {
            let config_dir = ($env.HOME | path join ".config" $type)
            if ($config_dir | path exists) {
                edit $config_dir
            } else {
                print "Usage: dotfiles [.|cron|fish|git|powerline]"
            }
        }
    }
}
