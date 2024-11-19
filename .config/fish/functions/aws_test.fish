function aws_test \
    --description='Test AWS credentials' \
    --argument-names profile_name

    if test -z $argname
        set profile_name default
    end

    aws sts get-caller-identity \
        --no-cli-pager \
        --profile $profile_name
end
