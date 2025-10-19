#!/usr/bin/env fish
# Prints a count of all functions
function func_count
    set -l all (string trim (functions | wc -w))
    set -l custom (string trim (find ~/.config/fish/functions -type f -maxdepth 1 -name '*.fish' | wc -l))
    set -l plugins (string trim (find ~/.config/fish/functions -type l -maxdepth 1 -name '*.fish' | wc -l))
    set -l autoloaded (string trim (ls -1 ~/.config/fish/functions/*.fish | wc -l))

    echo "Functions: $all ($custom custom, $plugins plugins, $autoloaded autoloaded)"
end
