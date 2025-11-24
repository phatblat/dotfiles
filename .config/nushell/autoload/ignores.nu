# Standard ignored files
export def ignores [] {
    [
        # macOS
        .DS_Store
        # Xcode
        "*.xccheckout"
        "*.xcscmblueprint"
        xcuserdata
        Carthage/
        Pods/
        # Swift PM
        .build/
        .swiftpm/
        # Bundler
        .rubygems/
        bin/
        # Gradle
        build/
        .gradle/
        gradlew.bat
        # IntelliJ IDEA
        .idea/
        "*.iml"
        "*.hprof"
        # VS Code
        .classpath
        .project
        .settings
        .vscode/
        # Rust
        target/
        # CMake
        .cxx/
        cmake-build-debug/
        .externalNativeBuild/
        # Java
        "heapdump.*.phd"
        "javacore.*.txt"
        # Visual Studio, MSBuild
        "*.dll"
        .vs/
        obj/
        packages/
        # Bazel
        "bazel-*"
        # Buck2
        buck-out/
        # Python
        __pycache__/
        # Node.js
        node_modules/
        # npm
        .npm/
    ]
}
