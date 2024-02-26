function pushf --description 'Force a git push.'
    # "force-with-lease": You assume you took the lease on the ref when you fetched to decide what the rebased history should be, and you can push back only if the lease has not been broken.
    push --force-with-lease $argv
end
