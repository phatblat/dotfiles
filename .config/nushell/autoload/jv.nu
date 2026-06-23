# Dependencies:
#   functions: none
#   builtins:  lines first split row str replace get
#   externals: java

# Display the installed Java version number by parsing 'java -version' stderr output
export def jv [] {
    let raw = (do { ^java -version } | complete | get stderr)
    let first_line = ($raw | lines | first)
    # Line format: 'java version "1.8.0_131"' or 'openjdk version "11.0.2" ...'
    let parts = ($first_line | split row " ")
    $parts | get 2 | str replace --all '"' ''
}
