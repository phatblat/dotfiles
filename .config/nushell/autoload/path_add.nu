# Dependencies:
#   functions: none
#   builtins:  path exists print
#   externals: none

# Prepend a directory to PATH if it exists and is not already present
export def --env path_add [directory: string] {
    if ($directory | is-empty) {
        error make { msg: "Usage: path_add <directory>" }
    } else if not ($directory | path exists) {
        print $"Directory not found: ($directory)"
    } else if $directory not-in $env.PATH {
        $env.PATH = ($env.PATH | prepend $directory)
    }
}
