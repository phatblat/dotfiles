# Updates the build.gradle and runs the wrapper task
export def gradle_wrapper_add [] {
    let gradleVersion = (gv)

    let wrapper_config = $"

task removeBatchFile(type: Delete) { delete 'gradlew.bat' }

wrapper {
    gradleVersion = '($gradleVersion)'
    distributionType = 'ALL'
    finalizedBy removeBatchFile
}
"

    $wrapper_config | save --append build.gradle

    gradle wrapper
}
