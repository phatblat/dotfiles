# Wrapper for ps which isolates processes containing
function psgrep --argument-names process
    if test -z "$process"
        echo "Usage: psgrep process"
        return 1
    end

    ps aux | grep --invert-match grep | grep $process
end
