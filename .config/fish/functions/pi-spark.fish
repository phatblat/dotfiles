#!/usr/bin/env fish
# Run Pi with the Spark Qwen model.
function pi-spark
    pi --provider spark --model nvidia/Qwen3.6-35B-A3B-NVFP4 $argv
end
