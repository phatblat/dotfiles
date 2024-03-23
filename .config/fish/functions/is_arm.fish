function is_arm \
    --description 'Tests whether the current CPU arch is ARM'

    # Apple calls uses the arm64 alias for aarch64
    test arm64 = (uname -m)
end
