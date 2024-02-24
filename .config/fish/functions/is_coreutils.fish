function is_coreutils \
    --description 'Tests whether coreutils is installed'

    # brew list coreutils >/dev/null 2>&1
    return 1
end
