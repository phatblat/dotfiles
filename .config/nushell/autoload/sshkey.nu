# Dependencies:
#   functions: none
#   builtins:  path exists print
#   externals: none

# Find and return the path of the primary SSH public key file
export def sshkey [] {
    let ed = $"($env.HOME)/.ssh/id_ed25519.pub"
    let rsa = $"($env.HOME)/.ssh/id_rsa.pub"
    if ($ed | path exists) {
        $ed
    } else if ($rsa | path exists) {
        $rsa
    } else {
        print --stderr "Error: No SSH key file found."
        error make { msg: "No SSH key file found." }
    }
}
