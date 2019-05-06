# Show all installed JDKs.
function showjdks
    if is_mac
        /usr/libexec/java_home --verbose $argv
    else if is_linux
        ll /usr/lib/jvm/
    end
end
