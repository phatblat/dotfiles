# Installs the gradle wrapper
export def gradle_wrapper [
    gradle_version?: string  # Gradle version (defaults to current gradle version)
] {
    let version = if ($gradle_version | is-empty) {
        gv
    } else {
        $gradle_version
    }

    gradle wrapper --gradle-version $version

    if ("gradlew.bat" | path exists) {
        rm -f gradlew.bat
    }
}
