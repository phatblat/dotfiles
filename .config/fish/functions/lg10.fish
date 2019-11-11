function lg10 --description='Pretty history graph with ten commits'
    set -l commit_count 10

    git log \
        -$commit_count \
        --graph \
        --abbrev-commit \
        --date=relative \
        --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' \
        $argv
end
