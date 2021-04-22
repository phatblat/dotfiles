# Displays path to the current JDK.
function whichjdk
    if is_mac
        echo JAVA_HOME: $JAVA_HOME

        if string match --entire --quiet /Library/Java/JavaVirtualMachines $JAVA_HOME
            # System JVMs
            /usr/libexec/java_home $argv
        else
            # SDKman?
            if test -d $sdkman_prefix/candidates/java/current
                ll $sdkman_prefix/candidates/java/current
            end
        end

        java -version
    else if is_linux
        java -version
    end
end
