function gw --description 'Invokes a build using the Gradle wrapper script.'
    if test -e ./gradlew
        ./gradlew $argv
        return
    end

    error "There is no Gradle wrapper in the current dir."
    gradle $argv
end
