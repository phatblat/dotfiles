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
        .swiftpm/ \
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
        .vscode/ \
        # Rust
        target/ \
        # CMake
        .cxx/ \
        cmake-build-debug/ \
        .externalNativeBuild/ \
        # Java
        'heapdump.*.phd' \
        'javacore.*.txt' \
        # Rust/Cargo
        target/ \
        # Visual Studio, MSBuild
        '*.dll' \
        .vs/ \
        packages/ \
        obj/
end
