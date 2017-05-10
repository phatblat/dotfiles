# Prompt the user for a yes/no response. Returns 0 (success) for YES and 1 (error) for NO.
# Plugin Dependency: get
function yn --argument-names prompt
    get --prompt $prompt --default=y \
        | read -l answer

    switch $answer
        case y yes Y YES
            echo YES
            return 0
        case n no N NO
            echo NO
            return 1
    end
end
