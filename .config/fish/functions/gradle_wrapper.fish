function gradle_wrapper --argument-names version --description='Upstalls the gradle wrapper'
    if test -z "$version"
        set version (gv)
    end

    gradle wrapper --gradle-version $version
    if test -e gradlew.bat
        rm -f gradlew.bat
    end
end
