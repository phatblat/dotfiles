function ___stat \
    --description='Disabled wrapper for stat' \
    --wraps='stat' \
    --argument-names argname

    # echo "stat function"

    # macOS - https://ss64.com/osx/stat.html
    # /usr/bin/stat: illegal option -- -
    # usage: stat [-FlLnqrsx] [-f format] [-t timefmt] [file ...]

    # coreutils
    # stat (GNU coreutils) 8.31
    # Copyright (C) 2019 Free Software Foundation, Inc.
    # License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>.
    # This is free software: you are free to change and redistribute it.
    # There is NO WARRANTY, to the extent permitted by law.

    set -l stat_version (command stat --version)
    # echo "stat_version: $stat_version"
    if not string match --entire --quiet -- "coreutils" $stat_version
        error "WARN: stat in PATH is not part of coreutils"
    end

    command stat $argv
end
