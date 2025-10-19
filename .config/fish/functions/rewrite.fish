#!/usr/bin/env fish
function rewrite \
    --argument-names field old_value new_value \
    --description='Rewrite commits changing author/committer name/email/time environment variables.'

    if test (count $argv) -ne 3
        error "Usage: rewrite email old_value new_value"
        return 1
    end

    if test $field != "email"
        error "Only email replacements are currently supported."
        error "Usage: rewrite email old_value new_value"
        return 2
    end

    if not command --search git-filter-repo > /dev/null
        error "git-filter-repo is installed"
        return 3
    end

    # https://htmlpreview.github.io/?https://github.com/newren/git-filter-repo/blob/docs/html/git-filter-repo.html#CALLBACKS
    git filter-repo --force \
        --email-callback \
        "return email.replace(b\"$old_value\", b\"$new_value\")"
end
