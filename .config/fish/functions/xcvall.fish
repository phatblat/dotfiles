function xcvall --description='Lists versions of all installed copies of Xcode.'
    mdfind kMDItemCFBundleIdentifier=com.apple.dt.Xcode
end
