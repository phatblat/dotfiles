function add-gradle-wrapper --description="Updates the build.gradle and runs the wrapper task."

    # Configure the wrapper task.
    # https://github.com/fish-shell/fish-shell/issues/540#issuecomment-52779637
    printf "\

task removeBatchFile(type: Delete) { delete 'gradlew.bat' }

wrapper {
    gradleVersion = '4.1'
    distributionType = 'ALL'
    finalizedBy removeBatchFile
}
" | cat >> build.gradle

    # Install the wrapper
    gradle wrapper
end
