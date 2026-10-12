# shacopy - Copies the SHA1 hash of the HEAD commit to the general pasteboard
export def shacopy [] {
    headsha | ^pbcopy
}
