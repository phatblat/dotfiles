# Run Pi with the Spark Qwen model.
export def --wrapped pi-spark [...args] {
    ^pi --provider spark --model Inferact/Qwen3.8-27B-NVFP4 ...$args
}
