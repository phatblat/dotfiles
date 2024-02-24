function sshupload \
    --description 'Uploads public RSA SSH key to GitHub profile. Requires manual entry of GitHub OTP code.' \
    --argument-names key_file

    if test -z $key_file
        set key_file (sshkey)
    end

    if not test -f $key_file
        error "No SSH key found at $key_file"
        return 1
    end

    set -l token $DOTFILES_GITHUB_TOKEN
    if test -z $token
        error "Please set DOTFILES_GITHUB_TOKEN in .envrc"
        return 2
    end

    set -l github_user phatblat
    set -l key (cat $key_file)
    set -l title $USER@$HOST_(date +%Y%m%d%H%M%S)

    # Upload default SSH key to GitHub
    echo "Uploading SSH public key to GitHub [$key_file]"

    # echo -n "Password for GitHub user $github_user: "
    # read passowrd

    # echo -n "GitHub OTP code: "
    # read otpcode

    # https://developer.github.com/v3/auth/#using-the-oauth-authorizations-api-with-two-factor-authentication
    curl \
        --request POST \
        --url "https://api.github.com/user/keys" \
        --header "Authorization: token $token" \
        --data "{\"title\":\"$title\",\"key\":\"$key\"" \
        --verbose
end
