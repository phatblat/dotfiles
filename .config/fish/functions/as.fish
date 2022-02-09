function as \
    --description='Open project in Android Studio' \
    --argument-names path

    set -l app ~/Library/Application\ Support/JetBrains/Toolbox/apps/AndroidStudio/ch-0/211.7628.21.2111.8139111/Android\ Studio.app

    if test -z $path
        set path .
    end

    open -a $app $path
end
