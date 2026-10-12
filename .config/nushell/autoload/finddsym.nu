# finddsym - Locates a dSYM file with the given UUID
export def finddsym [uuid?: string] {
    if ($uuid | is-empty) {
        error make { msg: "Usage: finddsym uuid" }
    }
    ^mdfind $"com_apple_xcode_dsym_uuids == <($uuid)>"
}
