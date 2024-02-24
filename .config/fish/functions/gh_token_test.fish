function gh_token_test \
    --description 'Tests the GitHub personal access token in DOTFILES_GITHUB_TOKEN'
    set -l token $DOTFILES_GITHUB_TOKEN
    if test -z $token
        error "Please set DOTFILES_GITHUB_TOKEN in .envrc"
        return 2
    end

    curl -u phatblat:$token https://api.github.com/user
end
