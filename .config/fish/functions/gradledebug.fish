# Toggle Gradle debugging.
function gradledebug
    if echo $GRADLE_OPTS | grep debug >/dev/null
        set --export GRADLE_OPTS $GRADLE_HEAP_SPACE
        echo "Gradle debugging off"
    else
        set --export GRADLE_OPTS "$GRADLE_HEAP_SPACE -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005"
        echo "Gradle debugging on"
        echo "GRADLE_OPTS: $GRADLE_OPTS"
    end
end
