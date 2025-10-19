#!/usr/bin/env fish
# Alias for curl_download.
function cdown --argument-names url
    if test -z "$url"
        echo "Usage: cdown url"
        return 1
    end

    curl_download $url
end
