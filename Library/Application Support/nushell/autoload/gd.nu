# Launch gradle in debug mode
export def gd [...args: string] {
    gw -Dorg.gradle.debug=true --no-daemon ...$args
}
