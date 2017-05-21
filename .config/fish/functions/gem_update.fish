# Updates a Ruby gem at the system level (requires sudo permissions).
# Binstubs are installed to /usr/local/bin alongside Homebrew binaries.
# This command will fail (even with sudo) without --bindir being directed
# do a user-owned dir.
function gem_update --argument-names gem_name
    if test -z gem_name ^/dev/null
        echo "Usage: gem_update gem_name ..."
        return 1
    end

    if test -n "$argv" -a (count $argv) -gt 1
        set argv $argv[2..-1]
    else
        set --erase argv
    end

    gem update --force $gem_name --bindir (brew_home)/bin $argv
end
