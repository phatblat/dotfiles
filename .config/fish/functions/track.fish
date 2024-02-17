function track --wraps=git \
    --description='Creates a local tracking branch.' \
    --argument-names remote_branch local_name
    if test -z $remote_branch
        echo "Usage: track remote_branch [local_name]"
        return 1
    end
    if test -z $local_name
        c --track $remote_branch
        return 0
    end
    c --track $remote_branch -b $local_name
end
