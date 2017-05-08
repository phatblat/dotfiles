# Prints a formatted version of a JSON file.
function prettyjson
    python -m json.tool $argv
end
