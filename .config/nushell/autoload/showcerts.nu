# showcerts - Shows server certificate information
export def showcerts [host_name: string, port: int = 443] {
    if ($host_name | is-empty) {
        error make { msg: "Usage: showcerts host_name.com [443]" }
    }
    null | ^openssl s_client -connect $"($host_name):($port)" -showcerts e> /dev/null
}
