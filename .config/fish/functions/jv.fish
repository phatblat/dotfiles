# Example output (goes to stderr!):
# java version "1.8.0_131"
# Java(TM) SE Runtime Environment (build 1.8.0_131-b11)
# Java HotSpot(TM) 64-Bit Server VM (build 25.131-b11, mixed mode)
function jv --description='Displays the Java version number'
    set -l output (java -version 2>&1)
    set -l java_version (string replace --all '"' '' (string split ' ' $output[1])[-1])
    echo $java_version
end
