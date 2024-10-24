function jdk \
    --description 'Manage installed JDKs.' \
    --argument-names command jdk_path quiet

    if is_linux
        which java
        java -version
        return
    end

    set --local ANDROID_STUDIO_PRERELEASE ""
    set --local ANDROID_STUDIO "$HOME/Applications/Android Studio$ANDROID_STUDIO_PRERELEASE.app"

    switch $command
        case list
            # List all installed JDKs
            echo 🖥 /usr/libexec/java_home
            /usr/libexec/java_home --verbose $argv

            echo
            echo 🖥 /Library/Java/JavaVirtualMachines
            ls -1 /Library/Java/JavaVirtualMachines

            # if test -d
            if test -d "$ANDROID_STUDIO"
                echo
                echo 🤖 Android Studio
                echo $ANDROID_STUDIO/Contents/jbr/Contents/Home
            end

            set -l jabba_path $HOME/.jabba/jdk
            if test -d $jabba_path
                echo
                echo 🐸 Jabba Java candidates in $jabba_path
                ls -1 $jabba_path
            end
        case set
            jdk_set $jdk_path $quiet
        case studio
            jdk_set "$ANDROID_STUDIO/Contents/jbr/Contents/Home" $quiet
        case '*' current
            # Prints info about the currently selected JDK
            set -l java_cmd (which java)
            echo JAVA_HOME: $JAVA_HOME
            echo which java $java_cmd
            lipo -info $java_cmd
            java -version
            echo CPPFLAGS: $CPPFLAGS
    end
end

function jdk_set \
    --description 'Activates a JDK' \
    --argument-names jdk_path quiet

    # Test JDK path
    if test "$jdk_path" = -
        # no-op
        echo "Skipping jdk_path check"
    else if not test -d "$jdk_path"
        error "Path not found: $jdk_path"
        return 2
    else if not test -f "$jdk_path/bin/java"
        error "No java binary found at path: $jdk_path/bin/java"
        return 3
    end

    # Version argument uses macOS java_home utility
    # set --local jhome /usr/libexec/java_home
    # set path (eval $jhome --version $java_version)
    # set --local last_error $status
    # if test $last_error != 0
    #     eval $jhome --verbose
    #     return $last_error
    # end

    # JAVA_OPTS
    # set --local common_options "-Xms256m -Xmx512m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m"
    # Suppressing Groovy warnings when gradle invoked from Java 9+
    # https://github.com/gradle/gradle/issues/2995
    # https://issues.apache.org/jira/browse/GROOVY-8339
    # set --local java9_options "--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.invoke=ALL-UNNAMED"

    # set --local major_version (string split . $java_version)[1]
    # if test $major_version -lt 9
    #     set --export --global JAVA_OPTS $common_options
    # else
    #     set --export --global JAVA_OPTS "$common_options $java9_options"
    # end
    # echo JAVA_OPTS: $JAVA_OPTS

    # Set JAVA_HOME and add to path
    set --export --global JAVA_HOME "$jdk_path"
    path_add $JAVA_HOME/bin

    # Set CPPFLAGS if there are no spaces in jdk_path
    if not has_space "$jdk_path"
        set --export --global CPPFLAGS "$CPPFLAGS -I$jdk_path/include"
    end

    if test -z $quiet
        jdk current
    end
end
