# entitlements - Display entitlements in the codesign information of a bundle
export def --wrapped entitlements [...args] {
    ^codesign -d --entitlements :- ...$args
}
