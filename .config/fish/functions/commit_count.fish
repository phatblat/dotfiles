# Count commits by date for a branch over a time period
function commit_count --description 'Show commit count by date for a branch'
    set -l days 7
    set -l branch (git rev-parse --abbrev-ref HEAD 2>/dev/null)

    if test (count $argv) -ge 1
        set days $argv[1]
    end

    if test (count $argv) -ge 2
        set branch $argv[2]
    end

    git log $branch --since="$days days ago" --pretty=format:"%ad" --date=short | sort | uniq -c | sort -rn
end
