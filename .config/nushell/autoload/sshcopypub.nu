# Copy SSH public key to pasteboard/clipboard
export def sshcopypub [] {
    let key_file = if ("~/.ssh/id_ed25519.pub" | path expand | path exists) {
        "~/.ssh/id_ed25519.pub" | path expand
    } else if ("~/.ssh/id_rsa.pub" | path expand | path exists) {
        "~/.ssh/id_rsa.pub" | path expand
    } else {
        print "Error: No SSH key file found."
        return 1
    }

    # Copy the key
    if ($nu.os-info.name == "macos") {
        open $key_file | ^pbcopy
    } else if ($nu.os-info.name == "linux") {
        open $key_file | ^xsel --clipboard
    }
}
