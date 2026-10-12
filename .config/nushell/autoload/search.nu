# search - Search for CLI tools through various package managers
export def search [...args] {
    if (is_linux) {
        print "Snap"
        print "-----------------------------------------------------------------"
        ^snap find ...$args

        print "APT"
        print "-----------------------------------------------------------------"
        ^apt search ...$args
    } else if (is_mac) {
        print "Mac App Store"
        print "-----------------------------------------------------------------"
        ^mas search ...$args
    }

    print "Homebrew"
    print "-----------------------------------------------------------------"
    ^brew search ...$args
}
