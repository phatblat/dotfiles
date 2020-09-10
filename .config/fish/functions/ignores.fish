# Standard ignored files.
function ignores
    list -s \
        # macOS
        .DS_Store \
        # Xcode
        '*.xccheckout' \
        '*.xcscmblueprint' \
        xcuserdata \
        Carthage/ \
        Pods/ \
        # Swift PM
        .build/ \
        # Bundler
        .rubygems/ \
        bin/ \
        # Gradle
        build/ \
        .gradle/ \
        gradlew.bat \
        # IntelliJ IDEA
        .idea/ \
        '*.iml' \
        '*.hprof' \
        # VS Code
        .classpath \
        .project \
        .settings \
        .vscode/
end
