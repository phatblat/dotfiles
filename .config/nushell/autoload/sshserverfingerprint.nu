# sshserverfingerprint - Print fingerprint of server SSH key
export def sshserverfingerprint [host: string] {
    ^ssh-keyscan $host | ^ssh-keygen -lf -
}
