# Rewrite commits changing either the author or the committer email.
function rewrite --argument-names field old_email new_email
    if test (count $argv) -ne 3
        echo "Usage: rewrite author|committer old@email new@email"
        return 1
    end

    switch $field
    case "author"
        set attribute "GIT_AUTHOR_EMAIL"
    case "committer"
        set attribute "GIT_COMMITTER_EMAIL"
    case "both"
        # Recursive call replacing author first, then committer
        set attribute "GIT_AUTHOR_EMAIL"
    case '*'
        echo "Usage: rewrite author|committer old@email new@email"
        return 2
    end

    # Filter command is eval'd using sh
    set -l filter_command "if [[ \$$attribute == $old_email ]]; then $attribute=$new_email; fi; export $attribute"

    git filter-branch -f --env-filter $filter_command

    # Recursive call replacing author first, then committer
    if test $field = "both"
        rewrite "committer" $old_email $new_email
    end
end
