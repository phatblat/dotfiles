# Prints gradle version
export def gv [] {
    let output = (gradle --version | lines)
    let gradle_line = ($output | where $it =~ "^Gradle" | first)
    let gradle_version = ($gradle_line | split row " " | get 1)
    $gradle_version
}
