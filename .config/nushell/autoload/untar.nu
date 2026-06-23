# Dependencies:
#   functions: none
#   builtins:  path exists path type path basename split row first mkdir is-empty
#   externals: tar
# Note: zsh uses ${file_name%%.*} (greedy, strips all extensions). Since
# file_base (fish) only strips the last extension, the greedy logic is inlined
# here via `path basename | split row '.' | first`.

# Extract a .tar.gz archive into a new directory named after the archive (all extensions stripped)
export def untar [file_name?: string] {
    if ($file_name == null or ($file_name | is-empty)) {
        error make { msg: "Usage: untar file.tar.gz" }
    }

    if not ($file_name | path exists) or (($file_name | path type) != "file") {
        error make { msg: $"File not found: ($file_name)" }
    }

    # Strip all extensions (greedy): "archive.tar.gz" -> "archive"
    let dir_name = $file_name | path basename | split row '.' | first

    if ($dir_name | path exists) and (($dir_name | path type) == "dir") {
        error make { msg: $"Extraction directory already exists: ($dir_name)" }
    }

    mkdir $dir_name
    ^tar --extract --gunzip --verbose --file $file_name --directory $dir_name
}
