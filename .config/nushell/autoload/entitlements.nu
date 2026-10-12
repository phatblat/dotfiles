# entitlements - Display entitlements in the codesign information of a bundle
export def entitlements [...args] {
    ^codesign -d --entitlements :- ...$args
}
