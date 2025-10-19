#!/usr/bin/env fish
# Shows server certificate information.
function showcerts --argument-names host_name port
    if test -z $host_name
        echo "Usage: savecerts host_name.com [443]"
        return 1
    end

    if test -z $port
        # Set default port value
        set port 443
    end

    # Shut off stderr
    # exec ^>/dev/null

    # eval $OPENSSL_PATH s_client -connect $host_name:$port -showcerts </dev/null ^>/dev/null
    # Redirect stdout to itself to work around 'Expected a string, but instead found a redirection' error with redirecting stderr.
    set -l output (eval $OPENSSL_PATH s_client -connect $host_name:$port -showcerts </dev/null)
    #count (eval $OPENSSL_PATH s_client -connect $host_name:$port -showcerts </dev/null)
    # set -l output (eval $OPENSSL_PATH s_client -connect $host_name:$port -showcerts </dev/null)
    #echo $output

    if test -z "$output"
        return 2
    end

    for line in $output
        echo $line
    end

    # string length "$output"
    # string join "\n" $output #| less
    # return $output
end
