# Generates a new private RSA SSH key at ~/.ssh/id_rsa with an optional comment.
# Comment defaults to USER@hostname.
function sshnewkey --argument-names comment
    if test -z $comment
        set comment "$USER@"(hostname)
    end

    set -l keyfile ~/.ssh/id_rsa

    ssh-keygen \
        -t rsa \
        -C $comment \
        -f $keyfile
end
