# showcert - Prints server certificate file details
export def showcert [cert_file: path] {
    if not ($cert_file | path exists) {
        error make { msg: "Usage: showcert cert_file" }
    }
    let openssl = ($env.OPENSSL_PATH? | default "openssl")
    ^$openssl x509 -in $cert_file -inform DER -text -noout
}
