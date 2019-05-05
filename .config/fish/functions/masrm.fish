function masrm \
        --description='Uninstall mas package'

    if not type -q mas
        error mas is not installed
        return 1
    end

    set --local binary /usr/local/bin/mas
    set --local framework /usr/local/Frameworks/MasKit.framework

    if not test -f $binary
        error No mas found at $binary
        return 2
    else if not test -d $framework
        error No MasKit.framework found at $framework
        return 3
    end

    # Packges are installed by root
    set --local owner (fileowner $binary)
    if test root = $owner
        trash $binary
    else if test $USER = $owner
        brew uninstall mas
    end

    if type -q mas
        error Another copy of mas is still installed
        masshow
        return 4
    end
end
