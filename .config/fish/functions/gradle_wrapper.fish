# gradle_wrapper
function gradle_wrapper --argument-names version
    if test -z "$version"
        set version 3.5
    end

    gradle wrapper --gradle-version $version
    if test -e gradlew.bat
        rm -f gradlew.bat
    end
end
