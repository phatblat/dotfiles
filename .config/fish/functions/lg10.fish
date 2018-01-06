function lg10 --description='Pretty history graph with ten commits'
    git log \
        -10 \
        --graph \
        --abbrev-commit \
        --date=relative \
        --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' \
        $argv
end

