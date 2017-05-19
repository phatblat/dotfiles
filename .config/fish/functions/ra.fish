function ra --description 'Adds a git remote' --argument name url
    git remote add $name $url
    and rv
    and fetch $name
end
