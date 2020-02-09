function u2f_key_add \
        --description='Add U2F key' \
        --argument-names argname

    set -l yubico_dir ~/.config/Yubico
    set -l key_file u2f_keys

    mkdir $yubico_dir

    if not test -f $key_file
        echo "Adding initial U2Fkey to $key_file"
        pamu2fcfg > $key_file
    else
        echo "Appending U2F key to $key_file"
        pamu2fcfg -n >> $key_file
    end

    popd
end
