# https://swift.org/download/#installation-1
function swift_verify \
    --description swift_verify \
    --argument-names tarball

    # # https://swift.org/download/#installation-1
    gpg --keyserver hkp://pool.sks-keyservers.net --refresh-keys Swift

    # Then, use the signature file to verify that the archive is intact:
    gpg --verify $tarball.sig
end
