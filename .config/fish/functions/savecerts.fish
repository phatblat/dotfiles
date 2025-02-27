# Saves server certificates in binary (DER) format for a given host_name and optional port.
function savecerts --argument-names host_name port
    if test -z $host_name
        echo "Usage: savecerts host_name.com [443]"
        return 1
    end

    if test -z $port
        # Set default port value
        set port 443
    end

    #set -l output (eval $OPENSSL_PATH s_client -connect $host_name:$port -showcerts </dev/null) #2>/dev/null)
    showcerts $host_name $port >$host_name.pem

    # TODO: Capture stderr to catch message
    #if test $parsed_output[3] = "refused"
    #    echo "Error connecting to $host_name:$port ("(echo $parsed_output[2..4])")"
    #    return 2
    #end

    # Convert PEM to DER
    #eval $OPENSSL_PATH x509 -in $host_name.pem -outform DER >$host_name.der
    eval $OPENSSL_PATH x509 -in $host_name.pem -out $host_name.der -outform DER

    # FIXME: File is missing immediately after command
    #sleep 1 # File isn't written immediately
    # if is_coreutils
    #stat -f%z $host_name.dir
    #echo $host_name.der (stat -f%z $hostnane.der) bytes

    # Clean up temp PEM file
    # rm $host_name.pem

    echo Certificate saved to file: $host_name.der
end
