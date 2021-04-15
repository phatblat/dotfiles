function is_arm \
    --description='Tests whether the current system is arm'

    test arm64 = (uname -m)
end
