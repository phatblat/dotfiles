# Displays the Java version number.
function jv
    # Example output:
    # java version "1.8.0_131"
    # Java(TM) SE Runtime Environment (build 1.8.0_131-b11)
    # Java HotSpot(TM) 64-Bit Server VM (build 25.131-b11, mixed mode)
    set -l output (java -version)[1]
    echo $output
end
