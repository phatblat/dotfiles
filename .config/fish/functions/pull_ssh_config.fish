function pull_ssh_config \
    --description 'Copies SSH config to local'

    if test phatmini = (hostname)
        echo 'pull_ssh_config should be run on a remote host'
        return 1
    end

    scp phatmini.c4:.ssh/config ~/.ssh/config
end
