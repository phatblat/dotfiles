function amendne \
    --description='Amend previous commit without editing the message.'

    git commit --verbose --amend --no-edit $argv
end
