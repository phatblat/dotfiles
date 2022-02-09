function as \
    --description='Open project in Android Studio' \
    --argument-names path

    set -l arctic_fox   ch-0/203.7935034
    set -l bumblebee    ch-1/211.7628.21.2111.8139111
    set -l chipmunk     ch-2/212.5457.46.2112.8094850
    set -l dolphin      ch-3/213.5744.223.2113.8103819

    set -l app ~/Library/Application\ Support/JetBrains/Toolbox/apps/AndroidStudio/$arctic_fox/Android\ Studio.app

    if test -z $path
        set path .
    end

    open -a $app $path
end
