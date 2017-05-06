
# null
function bdm
    git branch -d $(git branch --merged | grep -v "^*" | grep -v "master" | tr -d "\n")
end
