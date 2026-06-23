# Dependencies:
#   functions: none
#   builtins:  is-empty print
#   externals: security openssl

# Print signing certificate details by piping security find-certificate output through openssl x509 -text
export def signing_cert_details [cert_name: string] {
    if ($cert_name | is-empty) {
        print --stderr "Usage: signing_cert_details \"iOS Dev: Me\""
        print --stderr "Use the list_codesign_identities function to find the certificate name."
        error make { msg: "missing cert_name argument" }
    }
    ^security find-certificate -c $cert_name -p | ^openssl x509 -text
}
