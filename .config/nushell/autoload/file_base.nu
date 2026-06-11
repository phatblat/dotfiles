# Dependencies:
#   functions: none
#   builtins:  path parse is-empty
#   externals: none

# Print the base name of a file after dropping the last extension
export def file_base [file_name: string] {
    if ($file_name | is-empty) {
        error make { msg: "Usage: file_base [file]" }
    }
    $file_name | path parse | get stem
}
