function brew_cache_purge \
    --description='Purges the Homebrew cache'

    rm -rf (brew --cache)
end
