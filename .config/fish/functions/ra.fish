function ra --description 'Adds a git remote' --argument name url
    git remote add $name $url
    rv
end
