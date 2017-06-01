# Amend the previous git commit.
function amend
    toggle_wait on
    git commit --verbose --amend $argv
    toggle_wait off
end
