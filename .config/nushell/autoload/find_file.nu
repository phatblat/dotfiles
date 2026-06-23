# Dependencies:
#   functions: none
#   builtins:  is-empty path exists complete print
#   externals: mdfind find

# Finds files under the given base_dir (defaults to PWD) using both Spotlight and find
export def find_file [file_name: string, base_dir?: string] {
    if ($file_name | is-empty) {
        print "Missing file name"
        print "Usage: find_file file.yml /base/dir"
        return
    }

    ^mdfind -name $file_name
    print ""

    let dir = if ($base_dir == null or ($base_dir | is-empty)) { "." } else { $base_dir }

    if not ($dir | path exists) {
        print $"'($dir)' does not exist"
        return
    }

    print $"file_name: ($file_name)"
    print $"base_dir: ($dir)"
    print "-----------------------------------"

    do { ^find $dir -name $"*($file_name)*" -print } | complete | get stdout | print
}
