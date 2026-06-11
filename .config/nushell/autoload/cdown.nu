# Dependencies:
#   functions: curl_download
#   builtins:  none
#   externals: none

# Alias for curl_download — download a file using curl with common options
export def cdown [url: string] {
    curl_download $url
}
