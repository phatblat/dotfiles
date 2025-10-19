#!/usr/bin/env fish
function xcdl \
    --description "Downloads platform tools for Xcode" \
    --argument-names platform

    echo Xcode (xcv)

    # https://developer.apple.com/documentation/xcode/installing-additional-simulator-runtimes#Install-and-manage-Simulator-runtimes-from-the-command-line

    switch $platform
        case all
            # -downloadAllPlatforms download all platforms
            xcodebuild -downloadAllPlatforms
        case ios iOS
            # -downloadPlatform NAME download the platform NAME
            xcodebuild -downloadPlatform iOS
        case tvos tvOS
            xcodebuild -downloadPlatform tvOS
        case visionos visionOS
            xcodebuild -downloadPlatform visionOS
        case watchos watchOS
            xcodebuild -downloadPlatform watchOS
        case '*' list
            echo available platforms: ios tvos visionos watchos
    end
end
