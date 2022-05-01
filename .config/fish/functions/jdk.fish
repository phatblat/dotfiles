function jdk \
    --description='Manage installed JDKs.' \
    --argument-names command

    if is_linux
        which java
        java -version
        return
    end

    switch $command
        case list
            # List all installed JDKs
            echo 🖥 /usr/libexec/java_home
            /usr/libexec/java_home --verbose $argv

            echo
            echo 🖥 /Library/Java/JavaVirtualMachines
            ls -1 /Library/Java/JavaVirtualMachines

            set -l sdkman_path $HOME/.sdkman/candidates/java
            if test -d $sdkman_path
                echo
                echo 🧰 SDKman Java candidates in $sdkman_path
                ls -1 $sdkman_path
            end

            set -l jabba_path $HOME/.jabba/jdk
            if test -d $jabba_path
                echo
                echo 🐸 Jabba Java candidates in $jabba_path
                ls -1 $jabba_path
            end
        case set
            # Set current JDK
        case '*' current
            # Prints info about the currently selected JDK
            set -l java_cmd (which java)
            echo JAVA_HOME: $JAVA_HOME
            echo which java $java_cmd
            lipo -info $java_cmd
            java -version
    end


    # if string match --entire --quiet /Library/Java/JavaVirtualMachines $JAVA_HOME
    #     # System JVMs
    #     /usr/libexec/java_home $argv
    # else
    #     # SDKman?
    #     if test -d $sdkman_prefix/candidates/java/current
    #         ll $sdkman_prefix/candidates/java/current
    #     end
    # end

end
