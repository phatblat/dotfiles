function setjdk \
    --argument-names java_version \
    --description "Updates JAVA_HOME to point to the given JDK version."

    if is_linux
        set --export --global JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
        return
    end

    set --local sdkman_java_base $HOME/.sdkman/candidates/java
    set --local sdkman_symlink $sdkman_java_base/current
    if test -L $sdkman_symlink
        set java_version (readlink $sdkman_symlink)
        set path $sdkman_java_base/$java_version
    end

    if test -z $java_version
        echo "Usage: setjdk [1.8|1.8.0_111|path]"
        echo "Given no args the .sdkman/candidates/java/current file will be used"
        return 1
    end

    if test -d $path
        # Path set by SDKman, no-op (prevents java_home from being used)
    else if test -d $java_version
        # Test if we have been given an absolute path
        # Preserve path for JAVA_HOME
        set path $java_version

        # Use the last dir name as the version
        set java_version (string split '/' $java_version)[-1]
    else
        # Version argument uses macOS java_home utility
        set --local jhome /usr/libexec/java_home
        set path (eval $jhome --version $java_version)
        set --local last_error $status
        if test $last_error != 0
            eval $jhome --verbose
            return $last_error
        end
    end

    if not test -d $path
        error "Path not found: $path"
        return 2
    end

    # JAVA_HOME
    set --export --global JAVA_HOME $path
    # echo JAVA_HOME: $JAVA_HOME

    # JAVA_OPTS
    set --local common_options "-Xms256m -Xmx512m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m"
    # Suppressing Groovy warnings when gradle invoked from Java 9+
    # https://github.com/gradle/gradle/issues/2995
    # https://issues.apache.org/jira/browse/GROOVY-8339
    set --local java9_options "--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.invoke=ALL-UNNAMED"

    set --local major_version (string split . $java_version)[1]
    if test $major_version -lt 9
        set --export --global JAVA_OPTS $common_options
    else
        set --export --global JAVA_OPTS "$common_options $java9_options"
    end

    # echo JAVA_OPTS: $JAVA_OPTS
end
