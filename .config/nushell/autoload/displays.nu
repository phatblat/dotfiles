# Dependencies:
#   functions: none
#   builtins:  from json
#   externals: system_profiler

# Show info about connected displays as structured data
export def displays [] {
    ^system_profiler SPDisplaysDataType -json | from json
}
