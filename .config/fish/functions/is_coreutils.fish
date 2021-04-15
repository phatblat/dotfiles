function is_coreutils \
    --description='Tests whether coreutils is installed'

    brew list coreutils >/dev/null
end
