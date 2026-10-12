# prettyjson - Prints a formatted version of a JSON file
export def --wrapped prettyjson [...args] {
    ^python3 -m json.tool ...$args
}
