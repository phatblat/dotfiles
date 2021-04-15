# Saves server certificates in binary (DER) format for a given hostname and optional port.
function savecerts --argument-names hostname port
    if test -z $hostname
        echo "Usage: savecerts hostname.com [443]"
        return 1
    end

    if test -z $port
        # Set default port value
        set port 443
    end

    #set -l output (eval $OPENSSL_PATH s_client -connect $hostname:$port -showcerts </dev/null) #^/dev/null)
    showcerts $hostname $port >$hostname.pem

    # TODO: Capture stderr to catch message
    #if test $parsed_output[3] = "refused"
    #    echo "Error connecting to $hostname:$port ("(echo $parsed_output[2..4])")"
    #    return 2
    #end

    # Convert PEM to DER
    #eval $OPENSSL_PATH x509 -in $hostname.pem -outform DER >$hostname.der
    eval $OPENSSL_PATH x509 -in $hostname.pem -out $hostname.der -outform DER

    # FIXME: File is missing immediately after command
    #sleep 1 # File isn't written immediately
    # if is_coreutils
    #stat -f%z $hostname.dir
    #echo $hostname.der (stat -f%z $hostnane.der) bytes

    # Clean up temp PEM file
    # rm $hostname.pem

    echo Certificate saved to file: $hostname.der
end
