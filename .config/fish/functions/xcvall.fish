#!/usr/bin/env fish
function xcvall --description='Lists versions of all installed copies of Xcode.'
    mdfind kMDItemCFBundleIdentifier=com.apple.dt.Xcode

    echo
    echo "CLI tools"
    pkginfo com.apple.pkg.CLTools_Executables
end
