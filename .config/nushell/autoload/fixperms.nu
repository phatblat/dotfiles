# Dependencies:
#   functions: none
#   builtins:  is-empty
#   externals: find chmod

# Set files to 644 and directories to 755 under base_dir (default: current directory)
export def fixperms [base_dir?: string = "."] {
    let dir = if ($base_dir | is-empty) { "." } else { $base_dir }
    ^find $dir -type f -print -exec chmod 644 "{}" ";"
    ^find $dir -type d -print -exec chmod 755 "{}" ";"
}
