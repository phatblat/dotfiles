# Dependencies:
#   functions: none
#   builtins:  none
#   externals: uname sw_vers system_profiler

# Print system information: kernel, macOS version, and software profile
export def sysinfo [] {
    ^uname -a
    ^sw_vers -productVersion
    ^system_profiler SPSoftwareDataType
}
