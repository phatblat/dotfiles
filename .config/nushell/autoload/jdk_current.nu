# Dependencies:
#   functions: none
#   builtins:  print
#   externals: java lipo

# Show the current JDK: JAVA_HOME, which java, lipo arch info, and java -version
export def jdk_current [] {
    let java_cmd = (^which java | str trim)
    print $"JAVA_HOME: ($env.JAVA_HOME? | default '')"
    print $"which java: ($java_cmd)"
    ^lipo -info $java_cmd
    ^java -version
    print $"CPPFLAGS: ($env.CPPFLAGS? | default '')"
}
