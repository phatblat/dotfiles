# Update JAVA_HOME to point to the given JDK version.
function setjdk
    set -x JAVA_HOME (/usr/libexec/java_home --version $argv)
end
