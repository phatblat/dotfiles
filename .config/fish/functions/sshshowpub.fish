function sshshowpub \
    --description 'Prints SSH public key.'
    set key_file (sshkey)
    cat $key_file
end
