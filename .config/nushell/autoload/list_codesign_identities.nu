# Dependencies:
#   functions: none
#   builtins:  none
#   externals: security

# Lists code-signing identities using security find-identity
export def --wrapped list_codesign_identities [...rest] {
    ^security find-identity -v -p codesigning ...$rest
}
