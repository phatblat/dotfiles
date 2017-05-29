# Rename the 'origin' remote to 'phatblat'
function pborigin --argument-names arg1
    set -l all_remotes (git remote)
    if contains -- 'phatblat' $all_remotes
        echo "The phatblat remote is already set up."
        rv
        return 1
    end

    remote rename origin phatblat
    rv
end
