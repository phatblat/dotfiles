# Dependencies:
#   functions: none
#   builtins:  print
#   externals: none

# Print Warp terminal escape sequence to warpify a subshell
# See: https://docs.warp.dev/features/subshells#automatically-warpify-subshells
export def warpify [] {
    let dcs = "\u{001b}P"
    let st = (char -u 0000009c)
    print -n $"($dcs)\$f{\"hook\": \"SourcedRcFileForWarp\", \"value\": { \"shell\": \"fish\" }}($st)"
}
