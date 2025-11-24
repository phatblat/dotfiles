# Launch gradle in debug mode
export def gd [...args: string] {
    ./gradlew -Dorg.gradle.debug=true --no-daemon ...$args
}
