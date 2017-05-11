# Validates Xcode application binary integrity using `spctl`
# Migrated from ~/.dotfiles/xcode/xccheck.sh
function xccheck
    set -l app_dirs /Applications ~/Applications

    for app_dir in $app_dirs
        test -e $app_dir; or continue
        for xcode_version in (ls -d $app_dir/Xcode*.app)
            echo "Checking integrity of $xcode_version"
            spctl --assess --verbose "$xcode_version"
        end
    end
end
