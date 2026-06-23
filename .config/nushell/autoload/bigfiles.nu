# Dependencies:
#   functions: none
#   builtins:  lines each sort-by first last split row into int char
#   externals: du

# List the 10 biggest files in the current directory tree (sizes in KB)
export def bigfiles [] {
    print "File sizes in KB"
    ^du -ka . | lines | each { |l|
        let parts = $l | split row (char tab)
        { size: ($parts | first | into int), path: ($parts | last) }
    } | sort-by size --reverse | first 10
}
