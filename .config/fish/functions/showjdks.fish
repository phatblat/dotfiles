# Show all installed JDKs.
function showjdks
    /usr/libexec/java_home --verbose $argv
end
