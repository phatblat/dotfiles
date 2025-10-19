#!/usr/bin/env fish
function signing_cert_details \
    --description='Prints signing certificate details' \
    --argument-names cert_name

    if test -z $cert_name
        error "Usage: signing_cert_details \"iOS Dev: Me\""
        echo "Use the list_codesign_identities function to find the certificate name."
    end

    security find-certificate \
        -c "$cert_name" \
        -p \
        | openssl x509 -text
end
