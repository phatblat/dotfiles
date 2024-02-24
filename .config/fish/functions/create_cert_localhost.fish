# https://stackoverflow.com/questions/8169999/how-can-i-create-a-self-signed-cert-for-localhost
function create_cert_localhost \
    --description 'Create a self-signed certificate for localhost'

    echo "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth" | openssl req -x509 \
        -out localhost.crt \
        -keyout localhost.key \
        -newkey rsa:2048 \
        -nodes \
        -sha256 \
        -subj '/CN=localhost' \
        -extensions EXT \
        -config

    # https://www.humankode.com/ssl/create-a-selfsigned-certificate-for-nginx-in-5-minutes
    # sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout localhost.key -out localhost.crt -config localhost.conf
end
