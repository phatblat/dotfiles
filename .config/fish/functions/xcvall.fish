function xcvall --description='Lists versions of all installed copies of Xcode.'
    mdfind kMDItemCFBundleIdentifier=com.apple.dt.Xcode

    echo
    echo "CLI tools"
    pkgutil --pkg-info=com.apple.pkg.CLTools_Executables
end
