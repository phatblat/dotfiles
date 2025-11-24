# Debug gradle
export def gwd [...args: string] {
    ./gradlew -Dorg.gradle.debug=true --no-daemon --console=plain ...$args
}
