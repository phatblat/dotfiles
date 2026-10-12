# is_arm - Return true if running on ARM architecture
export def is_arm [] {
    (^uname -m | str trim) == "arm64"
}
