function sshnewkey \
    --description 'Generates a new private SSH key at ~/.ssh/id_ed25519 with an optional comment. Comment defaults to USER@hostname' \
    --argument-names comment

    if test -z $comment
        set comment "$USER@"(hostname)
    end

    set -l key_file ~/.ssh/id_ed25519

    ssh-keygen \
        -t ed25519 \
        -C $comment \
        -f $key_file
end
