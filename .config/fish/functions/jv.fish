#!/usr/bin/env fish
# Example output (goes to stderr!):
#
#    java version "1.8.0_131"
#    Java(TM) SE Runtime Environment (build 1.8.0_131-b11)
#    Java HotSpot(TM) 64-Bit Server VM (build 25.131-b11, mixed mode)
#
#    openjdk version "11.0.2" 2019-01-15
#    OpenJDK Runtime Environment 18.9 (build 11.0.2+9)
#    OpenJDK 64-Bit Server VM 18.9 (build 11.0.2+9, mixed mode)
function jv --description='Displays the Java version number'
    set -l output (java -version 2>&1)
    set -l first_line (string split ' ' $output[1])
    set -l java_version (string replace --all '"' '' $first_line[3])
    echo $java_version
end
