#!/usr/bin/env fish
# Download a file using curl with the most common options:
# -f, --fail            Fail silently on server errors.
# -L, --location        Follow redirects.
# -O, --remote-name     Write output to a local file named like the remote file we get.
# --remote-name-all     Changes the default action for all given URLs to be dealt with as if -O, --remote-name were used for each one.
# -#, --progress-bar    Display transfer progress as a simple progress bar.
function curl_download --argument-names url
    if test -z "$url"
        echo "Usage: curl_download url"
        return 1
    end

    curl \
        --fail \
        --location \
        --remote-name \
        --progress-bar \
        $argv
end
