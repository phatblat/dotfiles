# Show all installed JDKs.
function showjdks
    if is_mac
        /usr/libexec/java_home --verbose $argv

        set -l sdkman_path $HOME/.sdkman/candidates/java
        if test -d $sdkman_path
            echo
            echo 🧰 SDKman Java candidates in $sdkman_path
            ls -1 $sdkman_path
        end

        set -l jabba_path $HOME/.jabba/jdk
        if test -d $jabba_path
            echo
            echo 🐸 Jabba Java candidates in $jabba_path
            ls -1 $jabba_path
        end
    else if is_linux
        ll /usr/lib/jvm/
    end
end
