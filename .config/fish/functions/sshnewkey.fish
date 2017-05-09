# Generates a new RSA SSH key at ~/.ssh/id_rsa.pub with an optional comment.
# Comment defaults to $USER@$HOST.
function sshnewkey --argument-names comment
    if test -z $comment
        set comment "$USER@$HOST"
    end

    ssh-keygen \
        -t rsa \
        -C $comment \
        -f ~/.ssh/id_rsa.pub
end
