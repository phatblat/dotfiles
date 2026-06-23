# Dependencies:
#   functions: none
#   builtins:  print each
#   externals: none

# Pretty-print each entry in PATH on its own line
export def path_show [] {
    print "PATH"
    $env.PATH | each { |p| print $p }
}
