#!/usr/bin/env fish
# org.gradle.debug=true is the equivalent of: -Dorg.gradle.jvmargs="-XX:+HeapDumpOnOutOfMemoryError -Xmx4g -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5006" \
function gwd --description='Debug gradle'
    gw \
        -Dorg.gradle.debug=true \
        --no-daemon \
        --console=plain \
        $argv
end
