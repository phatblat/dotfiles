# Prints server certificate file details.
function showcert --argument-names $cert_file
    if not test -e $cert_file
        echo "Usage: showcert cert_file"
        return 1
    end

    openssl x509 -in $cert_file -text -noout
end
