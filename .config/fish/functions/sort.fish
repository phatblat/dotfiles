function sort \
        --wraps sort \
        --description="Wrapper for sort which forces byte ordering."

    set -lx LC_ALL C
    command sort $argv
end
