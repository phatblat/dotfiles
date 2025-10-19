#!/usr/bin/env fish
# Prompt the user for a yes/no response. Returns 0 (success) for YES and 1 (error) for NO.
function yn \
        --argument-names prompt
    read \
        --local answer \
        --prompt-str="$prompt> "

    switch $answer
        case y yes Y YES
            echo YES
            return 0
        case n no N NO
            echo NO
            return 1
        case '*'
            yn $prompt
    end
end
