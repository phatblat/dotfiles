function rewrite --argument-names field old_value new_value \
--description='Rewrite commits changing author/committer name/email/time environment variables.'
    if test (count $argv) -ne 3
        echo "Usage: rewrite author|committer|both|date|commit_date|dates old|commit new"
        return 1
    end

    switch $field
    case author
        set find_attribute GIT_AUTHOR_EMAIL
        set modify_attributes GIT_AUTHOR_EMAIL
    case committer
        set find_attribute GIT_COMMITTER_EMAIL
        set modify_attributes GIT_COMMITTER_EMAIL
    case both
        set find_attribute GIT_AUTHOR_EMAIL
        set modify_attributes GIT_AUTHOR_EMAIL GIT_COMMITTER_EMAIL
    case 'date'
        set find_attribute GIT_COMMIT
        set modify_attributes GIT_AUTHOR_DATE
    case commit_date
        set find_attribute GIT_COMMIT
        set modify_attributes GIT_COMMITTER_DATE
    case dates
        set find_attribute GIT_COMMIT
        set modify_attributes GIT_AUTHOR_DATE GIT_COMMITTER_DATE
    case '*'
        echo "Usage: rewrite author|committer|both|date|commit_date|dates old|commit new"
        return 2
    end

    # Check if a commit was specified
    if git rev-parse "$old_value" ^/dev/null
        set find_attribute GIT_COMMIT
    end

    # Filter command is eval'd using sh
    set -l filter_command "if [[ \$$find_attribute == '$old_value' ]]; then export"
    for attribute in $modify_attributes
        set filter_command "$filter_command $attribute='$new_value';"
    end
    set filter_command "$filter_command fi"

    echo "Filter command:"
    echo $filter_command

    # Modify commits
    git filter-branch --force --env-filter $filter_command
end
