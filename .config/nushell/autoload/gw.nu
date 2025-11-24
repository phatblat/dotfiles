# Invokes a build using the Gradle wrapper script
export def gw [...args: string] {
    if ("./gradlew" | path exists) {
        ./gradlew ...$args
    } else {
        print -e "There is no Gradle wrapper in the current dir."
        gradle ...$args
    }
}
