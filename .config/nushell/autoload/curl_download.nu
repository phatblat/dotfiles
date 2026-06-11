# Dependencies:
#   functions: none
#   builtins:  none
#   externals: curl

# Download a file using curl with common options: --fail, --location, --remote-name, --progress-bar
export def curl_download [
    url: string   # URL to download
    ...rest: string  # Additional curl arguments
] {
    ^curl --fail --location --remote-name --progress-bar $url ...$rest
}
