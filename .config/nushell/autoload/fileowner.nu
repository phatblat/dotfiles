# Dependencies:
#   functions: none
#   builtins:  is-empty str trim
#   externals: stat

# Displays the owner of a file
export def fileowner [file: string] {
    if ($file | is-empty) {
        error make { msg: "Usage: fileowner file" }
    }
    if ($nu.os-info.name == "macos") {
        # macOS: use stat -f '%Su' (find -printf not supported on BSD)
        ^stat -f "%Su" $file | str trim
    } else {
        ^stat --format=%U $file | str trim
    }
}
