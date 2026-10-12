# search - Search for CLI tools through various package managers
export def --wrapped search [...args] {
    if (is_linux) {
        print "Snap"
        print "-----------------------------------------------------------------"
        try { ^snap find ...$args }

        print "APT"
        print "-----------------------------------------------------------------"
        try { ^apt search ...$args }
    } else if (is_mac) {
        print "Mac App Store"
        print "-----------------------------------------------------------------"
        try { ^mas search ...$args }
    }

    print "Homebrew"
    print "-----------------------------------------------------------------"
    try { ^brew search ...$args }
}
