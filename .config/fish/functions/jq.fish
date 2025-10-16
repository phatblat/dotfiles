function jq --description "Wrapper around jq with input preservation on failure" --wraps jq
    set -l input (cat)

    # Use command jq to invoke the real jq command
    set -l output (echo "$input" | command jq $argv 2>/dev/null)

    # Check the exit status of jq
    if test $status -ne 0
        echo -e "jq failed. Input was:\n$input" >&2
        return 1
    end

    # If jq succeeds, print the output
    echo "$output"
end
