# Alias for Homebrew find_sparkle_appcast script
# https://github.com/caskroom/homebrew-cask/blob/master/doc/cask_language_reference/stanzas/appcast.md
function find_sparkle_appcast --argument-names app_bundle
    if test -z "$app_bundle"
        echo "Usage: find_sparkle_appcast /path/to/software.app"
        return 1
    else if not test -e $app_bundle
        echo $app_bundle" does not exist."
        return 2
    end

    eval (brew --repository)/Library/Taps/caskroom/homebrew-cask/developer/bin/find_sparkle_appcast $app_bundle
end
