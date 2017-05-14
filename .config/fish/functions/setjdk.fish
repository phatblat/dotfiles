# Update JAVA_HOME to point to the given JDK version.
function setjdk --argument-names version
    if test -z $version
        echo "Usage: setjdk 1.8 (or) setjdk 1.8.0_111"
        return 1
    end

    set --export JAVA_HOME (/usr/libexec/java_home --version $version)
end
