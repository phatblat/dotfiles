function sshupload \
    --description='Uploads public RSA SSH key to GitHub profile. Requires manual entry of GitHub OTP code.' \
    --argument-names keyfile

    if test -z $keyfile
        set keyfile ~/.ssh/id_rsa.pub
    end

    if not test -f $keyfile
        error "No SSH key found at $keyfile"
        return 1
    end

    set -l token $DOTFILES_GITHUB_TOKEN
    if test -z $token
        error "Please set DOTFILES_GITHUB_TOKEN in .envrc"
        return 2
    end

    set -l github_user phatblat
    set -l key (cat $keyfile)
    set -l title $USER@$HOST_(date +%Y%m%d%H%M%S)

    # Upload default SSH key to GitHub
    echo "Uploading SSH public key to GitHub [$keyfile]"

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
