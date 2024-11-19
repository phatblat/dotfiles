function amend \
    --description='Amend the previous git commit.'

    toggle_wait on
    git commit --verbose --amend $argv
    toggle_wait off
end
