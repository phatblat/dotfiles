# https://swift.org/download/#installation-1
function swift_pgp_key_import \
    --description 'Import the Swift PGP keys into your keyring'

    gpg --keyserver hkp://pool.sks-keyservers.net \
        --recv-keys \
        '7463 A81A 4B2E EA1B 551F  FBCF D441 C977 412B 37AD' \
        '1BE1 E29A 084C B305 F397  D62A 9F59 7F4D 21A5 6D5F' \
        'A3BA FD35 56A5 9079 C068  94BD 63BC 1CFE 91D3 06C6' \
        '5E4D F843 FB06 5D7F 7E24  FBA2 EF54 30F0 71E1 B235' \
        '8513 444E 2DA3 6B7C 1659  AF4D 7638 F1FB 2B2B 08C4' \
        'A62A E125 BBBF BB96 A6E0  42EC 925C C1CC ED3D 1561' \
        '8A74 9566 2C3C D4AE 18D9  5637 FAF6 989E 1BC1 6FEA'

    # https://swift.org/download/#active-signing-keys
    gpg --keyserver hkp://pool.sks-keyservers.net \
        --recv-keys \
        '8A74 9566 2C3C D4AE 18D9  5637 FAF6 989E 1BC1 6FEA'

    gpg --keyserver hkp://pool.sks-keyservers.net \
        --recv-keys \
        'A62A E125 BBBF BB96 A6E0  42EC 925C C1CC ED3D 1561'
end
