function aws_id \
    --description aws_id \
    --argument-names profile

    if test -z $profile
        set profile "--profile $profile"
    end

    aws sts get-caller-identity \
        --no-cli-pager
end
