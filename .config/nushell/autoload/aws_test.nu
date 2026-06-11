# Dependencies:
#   functions: none
#   builtins:  is-empty
#   externals: aws

# Test AWS credentials using sts get-caller-identity with an optional profile
export def aws_test [profile_name?: string] {
    let profile = if ($profile_name == null or ($profile_name | is-empty)) {
        "default"
    } else {
        $profile_name
    }
    ^aws sts get-caller-identity --no-cli-pager --profile $profile
}
