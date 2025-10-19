#!/usr/bin/env fish
function gradle_wrapper --argument-names gradle_version --description='Upstalls the gradle wrapper'
    if test -z "$gradle_version"
        set gradle_version (gv)
    end

    gradle wrapper --gradle-version $gradle_version
    if test -e gradlew.bat
        rm -f gradlew.bat
    end
end
