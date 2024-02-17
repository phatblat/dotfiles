# Collect a list of all commit authors from the current repo.
function list-authors --argument-names format
    if test -z $format
        set format name_email
    end

    switch $format
        case name_email
            # Name & email formatting
            set format '%an <%ae>'
        case name
            set format '%an'
        case email
            set format '%ae'
        case ruby
            # Ruby hash
            set format '"%an" => "%ae",'
        case '*'
            # Custom format
            set format $format
    end

    # Iterate over the hash of all commits
    for commit in (git rev-list --all)
        set all_authors $all_authors (git --no-pager show -s --format=$format $commit)
    end

    printf '%s\n' $all_authors \
        | sort \
        | uniq
end
