#!/usr/bin/env fish
# Prints server certificate file details.
function showcert --argument-names cert_file
    if not test -e $cert_file
        echo "Usage: showcert cert_file"
        return 1
    end

    eval $OPENSSL_PATH x509 -in $cert_file -inform DER -text -noout
end
