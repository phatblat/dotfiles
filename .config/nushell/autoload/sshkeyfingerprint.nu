# Dependencies:
#   functions: sshkey
#   builtins:  print str trim is-empty
#   externals: ssh-keygen

# Show the MD5 fingerprint of an SSH public key (defaults to key found by sshkey)
export def sshkeyfingerprint [
    file?: string  # Path to SSH public key file
] {
    let key_file = if ($file == null or ($file | str trim | is-empty)) {
        sshkey
    } else {
        $file
    }
    print -n $"[($key_file)] "
    ^ssh-keygen -l -E md5 -f $key_file
}
