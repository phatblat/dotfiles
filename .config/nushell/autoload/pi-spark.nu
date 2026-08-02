# Run Pi with the Spark Qwen model.
export def --wrapped pi-spark [...args] {
    ^pi --provider spark --model nvidia/Qwen3.6-35B-A3B-NVFP4 ...$args
}
