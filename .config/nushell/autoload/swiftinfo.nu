# Dependencies:
#   functions: none
#   builtins:  none
#   externals: xcrun swift

# Print information about the current Swift toolchain
export def swiftinfo [...args: string] {
    ^xcrun --find swift
    ^swift --version ...$args
}
