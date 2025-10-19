#!/usr/bin/env fish
function aws_test \
    --description='Test AWS credentials' \
    --argument-names profile_name

    if test -z $profile_name
        set profile_name default
    end

    aws sts get-caller-identity \
        --no-cli-pager \
        --profile $profile_name
end
