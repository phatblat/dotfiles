# Displays path to the current JDK.
function whichjdk
    if is_mac
        /usr/libexec/java_home $argv
    else if is_linux
        java -version
    end
end
