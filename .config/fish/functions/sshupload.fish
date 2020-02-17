function sshupload \
    --description='Uploads public RSA SSH key to GitHub profile. Requires manual entry of GitHub OTP code.'
    --argument-names keyfile

    if test -z $keyfile
        set keyfile ~/.ssh/id_rsa.pub
    end

    set -l github_user phatblat
    set -l key (cat $keyfile)
    set -l title $USER@$HOST_(date +%Y%m%d%H%M%S)

    # Upload default SSH key to GitHub
    echo "Uploading SSH public key to GitHub [$keyfile]"

    echo -n "Password for GitHub user $github_user: "
    read passowrd

    echo -n "GitHub OTP code: "
    read otpcode

    curl \
        --user "'"$github_user:$passowrd"'" \
        --header "X-GitHub-OTP: $otpcode" \
        --data "{\"title\":\"$title\",\"key\":\"$key\"" \
        --verbose \
        "https://api.github.com/user/keys"
end
