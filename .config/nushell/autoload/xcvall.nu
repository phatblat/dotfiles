# Dependencies:
#   functions: pkginfo
#   builtins:  print
#   externals: mdfind

# Lists all installed Xcode versions via Spotlight and CLI tools package info
export def xcvall [] {
    ^mdfind kMDItemCFBundleIdentifier=com.apple.dt.Xcode
    print ""
    print "CLI tools"
    pkginfo com.apple.pkg.CLTools_Executables
}
