# xccheck - Validates Xcode application binary integrity using spctl
export def xccheck [] {
    for xcode_version in (xclist -1 | lines) {
        print $"Checking integrity of ($xcode_version)"
        ^spctl --assess --verbose $xcode_version
    }
}
