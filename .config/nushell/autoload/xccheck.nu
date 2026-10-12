# xccheck - Validates Xcode application binary integrity using spctl
export def xccheck [] {
    # Same lookup order as xclist: /Applications first, then ~/Applications
    # (xclist prints rather than returns, so it can't be captured here)
    let xcodes = (
        ["/Applications" $"($env.HOME)/Applications"]
        | each { |dir| glob $"($dir)/Xcode*.app" }
        | flatten
    )
    for xcode_version in $xcodes {
        print $"Checking integrity of ($xcode_version)"
        try { ^spctl --assess --verbose $xcode_version }
    }
}
