# iphones - Show connected iOS devices
export def iphones [] {
    ^system_profiler SPUSBDataType
        | ^sed -n -E -e '/(iPhone|iPad)/,/Serial/s/ *Serial Number: *(.+)/\1/p'
}
