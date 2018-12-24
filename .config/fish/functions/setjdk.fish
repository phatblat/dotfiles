function setjdk \
        --argument-names version \
        --description "Updates JAVA_HOME to point to the given JDK version."
    if test -z $version
        echo "Usage: setjdk 1.8 (or) setjdk 1.8.0_111"
        return 1
    end

    set --local jhome /usr/libexec/java_home
    set --local major_version (string split . $version)[1]

    set --local path (eval $jhome --version $version)
    set --local last_error $status
    if test $last_error != 0
        eval $jhome --verbose
        return $last_error
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

    if test $major_version -lt 9
        set --export --global JAVA_OPTS $common_options
    else
        set --export --global JAVA_OPTS "$common_options $java9_options"
    end

    # echo JAVA_OPTS: $JAVA_OPTS
end
