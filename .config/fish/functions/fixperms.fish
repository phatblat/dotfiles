#!/usr/bin/env fish
# Sets all file and directory permissions to 644 and 755, respectively.
function fixperms --argument-names base_dir
    if test -z "$base_dir"
        set base_dir .
    end

    find $base_dir -type f -print -exec chmod 644 {} \;
    find $base_dir -type d -print -exec chmod 755 {} \;
end
