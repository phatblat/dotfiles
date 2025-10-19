#!/usr/bin/env fish
function xcfl \
    --description "Runs Xcode first launch if necessary or forced" \
    --argument-names force

    echo Xcode (xcv)

    if begin
            ! xcodebuild -checkFirstLaunchStatus
            or test "$force" = --force
        end
        echo Running Xcode first launch
        # install packages and agree to the licens -runFirstLaunch install packages and agree to the licens
        xcodebuild -runFirstLaunch -verbose
    end
end
