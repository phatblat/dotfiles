# Debug gradle
export def gwd [...args: string] {
    gw -Dorg.gradle.debug=true --no-daemon --console=plain ...$args
}
