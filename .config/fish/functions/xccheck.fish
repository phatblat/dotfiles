#!/usr/bin/env fish
# Validates Xcode application binary integrity using `spctl`
# Migrated from ~/.dotfiles/xcode/xccheck.sh
function xccheck
    for xcode_version in (xclist -1)
        echo "Checking integrity of $xcode_version"
        spctl --assess --verbose "$xcode_version"
    end
end
