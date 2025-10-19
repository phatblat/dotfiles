#!/usr/bin/env fish
# Prints Xcode version information.
#
# Interesting options:
#   -showsdks           _lists SDKs_
#   -sdk <iphoneos>     _SDK details_
function xv
    xcodebuild -version $argv
end
